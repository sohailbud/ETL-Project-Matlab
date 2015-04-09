ConDATASTRUCT=DATASTRUCT;

%% Fix CISION data
D=ConDATASTRUCT.Cision;
D.Subentity=[];
D=grpstats(D,{'Week','DMA_MKT_NAME'},'nansum');
D.Properties.RowNames={};
D.GroupCount=[];
D.Properties.VariableNames={'Week','DMA_MKT_NAME','Circulation','PRRecall','NetReach'};
ConDATASTRUCT.Cision=D;

%% Concatenate STRUCT
fname='Agency';

S=ConDATASTRUCT.(fname);
fnames=fieldnames(S);

indx=[];
for i = 1:numel(fnames)
   d=S.(fnames{i}); 
   indx=[indx;d(:,{'DMA_MKT_NAME','Week'})];
end
indx.Week=arrayfun(@num2str, indx.Week, 'Uniform', false);
indx.MKTWeek=strcat(indx.DMA_MKT_NAME,'|',indx.Week);
indx=unique(indx.MKTWeek);
indx=table(indx,'VariableNames',{'MKTWeek'});

for i = 1:numel(fnames)
    d=S.(fnames{i});
    d=[d(:,{'DMA_MKT_NAME','Week'}) d(:,setxor(d.Properties.VariableNames,{'DMA_MKT_NAME','Week'}))];
    cnames=['DMA_MKT_NAME','Week',strcat(fnames{i},setxor(d.Properties.VariableNames,{'DMA_MKT_NAME','Week'}))];
    d.Properties.VariableNames=cnames;
    
    d.Week=arrayfun(@num2str, d.Week, 'Uniform', false);
    d.MKTWeek=strcat(d.DMA_MKT_NAME,'|',d.Week);
    
    indx=outerjoin(indx,d,'LeftKeys','MKTWeek','RightKeys','MKTWeek','Type','left');
    indx.Properties.VariableNames{'MKTWeek_indx'}='MKTWeek';
    indx(:,{'DMA_MKT_NAME','Week','MKTWeek_d'})=[];
    
end

ConDATASTRUCT.(fname)=indx;

%% Table Var Name Replacement
sname='Cision';
d=ConDATASTRUCT.(sname);
d=[d(:,{'DMA_MKT_NAME','Week'}) d(:,setxor(d.Properties.VariableNames,{'DMA_MKT_NAME','Week'}))];
cnames=['DMA_MKT_NAME','Week',strcat(sname,setxor(d.Properties.VariableNames,{'DMA_MKT_NAME','Week'}))];
d.Properties.VariableNames=cnames;

d.Week=datenum(d.Week);

d.Week=arrayfun(@num2str, d.Week, 'Uniform', false);
d.MKTWeek=strcat(d.DMA_MKT_NAME,'|',d.Week);
d(:,{'DMA_MKT_NAME','Week'})=[];   
ConDATASTRUCT.(sname)=d;

%% Concatenate ConDATASTRUCT
S=ConDATASTRUCT;
fnames=fieldnames(S);

indx=[];
for i = 1:numel(fnames)
   d=S.(fnames{i}); 
   indx=[indx;d(:,{'MKTWeek'})];
end
indx=unique(indx.MKTWeek);
indx=table(indx,'VariableNames',{'MKTWeek'});


for i = 1:numel(fnames)
    d=S.(fnames{i});
    indx=outerjoin(indx,d,'LeftKeys','MKTWeek','RightKeys','MKTWeek','Type','left');
    indx.Properties.VariableNames{'MKTWeek_indx'}='MKTWeek';
    indx(:,{'MKTWeek_d'})=[];
end

%%
DMAWeek=[];
for i=1:size(indx,1)
    DMAWeek=[DMAWeek;strsplit(indx.MKTWeek{i},'|')];
end

%%
DMAWeek=array2table(DMAWeek,'VariableNames',{'DMA_MKT_NAME','Week'});
DMAWeek.Week=datestr(str2double(DMAWeek.Week));
indx=[DMAWeek indx];
indx.MKTWeek=[];
ConDATASTRUCT=indx;
clear indx;

%%
writetable(ConDATASTRUCT,'Humana Proof-of-Concept Data.txt','Delimiter','|');




