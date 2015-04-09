
%% LOAD
% load('DATASTRUCT.mat');
Project1Data=readtable('C:\Users\Sohail\Dropbox\Humana\Project 1\Data\Humana Medicare Proof-of-Concept Data.txt','Delimiter','|');
VarRef=readtable('C:\Users\Sohail\Dropbox\Humana\Medicare Q1 2015\DATA\OLD-NEW Variable Reference2.csv');
DMARef=readtable('C:\Users\Sohail\Dropbox\Humana\Medicare Q1 2015\DATA\DMAReference.csv');

%% ADD INDEX TO Project1DATA and FIX DISCREPANCIES (duplicate indix) BY SUMMING
Project1Data.DMA_MKT_NAME=strrep(Project1Data.DMA_MKT_NAME,',','-');

% Change to standard DMA names
for n=1:size(DMARef,1)
    loc=ismember(Project1Data.DMA_MKT_NAME,DMARef.Original{n});
    Project1Data(loc,'DMA_MKT_NAME')=DMARef.New(n);
end

Project1Data.Week=datenum(Project1Data.Week);
Project1Data.DMAWeek=strcat(Project1Data.DMA_MKT_NAME,'|',...
    arrayfun(@num2str, Project1Data.Week, 'Uniform', false));

Project1Data(:,{'DMA_MKT_NAME','Week'})=[];
Project1Data=grpstats(Project1Data,'DMAWeek','nansum');
Project1Data.Properties.RowNames={};
Project1Data.GroupCount=[];

varNames=Project1Data.Properties.VariableNames;
for i=2:numel(varNames)
    Project1Data.Properties.VariableNames{varNames{i}}= varNames{i}(8:end);
end

load gong.mat;
soundsc(y);
%% DELETE VARIABLES THAT ARE NOT IN NEW DATASET
Project1Data=Project1Data(:,['DMAWeek' setxor({'DMA_MKT_NAME','Week'},VarRef.AlternativeNamesForNEW_VARIABLES)']);

%% CREATE GLOBAL INDEX OF DMA_MKT_NAME and WEEK (INCLUDES Project1Data)
fnames=fieldnames(DATASTRUCT);
DMAWeek=[];
for i=1:numel(fnames)
    if istable(DATASTRUCT.(fnames{i}))
        D=DATASTRUCT.(fnames{i});
        D.Week=datenum(D.Week);
        D.DMAWeek=strcat(D.DMA_MKT_NAME,'|',arrayfun(@num2str, D.Week, 'Uniform', false));
        
        DMAWeek=[DMAWeek; D.DMAWeek];
    else
        fnamess=fieldnames(DATASTRUCT.(fnames{i}));
        for j=1:numel(fnamess)
            D=DATASTRUCT.(fnames{i}).(fnamess{j});
            D.Week=datenum(D.Week);
            D.DMAWeek=strcat(D.DMA_MKT_NAME,'|',arrayfun(@num2str, D.Week, 'Uniform', false));
            
            DMAWeek=[DMAWeek; D.DMAWeek];
        end
        
    end
end

DMAWeek=[DMAWeek; Project1Data.DMAWeek];
DMAWeek=table(unique(DMAWeek),'VariableNames',{'DMAWeek'});

%% LEFT JOIN Project1Data to DMAWeek

DMAWeek=outerjoin(DMAWeek,Project1Data,'LeftKeys','DMAWeek','RightKeys','DMAWeek','Type','left');
DMAWeek.Properties.VariableNames{'DMAWeek_DMAWeek'}='DMAWeek';
DMAWeek.DMAWeek_Project1Data=[];

%% REPLACE
fnames=fieldnames(DATASTRUCT);
for i=1:numel(fnames)
    if istable(DATASTRUCT.(fnames{i}))
        D=DATASTRUCT.(fnames{i});
        
        D.Week=datenum(D.Week);
        D.DMAWeek=strcat(D.DMA_MKT_NAME,'|',arrayfun(@num2str, D.Week, 'Uniform', false));
        D(:,{'DMA_MKT_NAME','Week'})=[];
        
        varNames=D.Properties.VariableNames;
        for k=1:numel(varNames)
            if ~strcmp(varNames{k},'DMAWeek')
                D.Properties.VariableNames{varNames{k}}=strcat(fnames{i},varNames{k});
            end
        end
        
        for k=1:size(VarRef,1)
            old=VarRef.NEW_VARIABLES{k};
            new=VarRef.AlternativeNamesForNEW_VARIABLES{k};
            try
                D.Properties.VariableNames{old}=new;
            catch
            end
        end
        
        [~,loc]=ismember(D.DMAWeek,DMAWeek.DMAWeek);
        varNames=D.Properties.VariableNames;
        for k=1:numel(varNames)
            DMAWeek(loc,varNames{k})=table(D.(varNames{k}));
        end
        
    else
        fnamess=fieldnames(DATASTRUCT.(fnames{i}));
        for j=1:numel(fnamess)
            D=DATASTRUCT.(fnames{i}).(fnamess{j});
            
            D.Week=datenum(D.Week);
            D.DMAWeek=strcat(D.DMA_MKT_NAME,'|',arrayfun(@num2str, D.Week, 'Uniform', false));
            D(:,{'DMA_MKT_NAME','Week'})=[];
            
            varNames=D.Properties.VariableNames;
            for k=1:numel(varNames)
                if ~strcmp(varNames{k},'DMAWeek')
                    D.Properties.VariableNames{varNames{k}}=strcat(fnamess{j},varNames{k});
                end
            end
            
            for k=1:size(VarRef,1)
                old=VarRef.NEW_VARIABLES{k};
                new=VarRef.AlternativeNamesForNEW_VARIABLES{k};
                try
                    D.Properties.VariableNames{old}=new;
                catch
                end
            end
            
            [~,loc]=ismember(D.DMAWeek,DMAWeek.DMAWeek);
            varNames=D.Properties.VariableNames;
            for k=1:numel(varNames)
                DMAWeek(loc,varNames{k})=table(D.(varNames{k}));
            end
        end
    end
end

load gong.mat;
soundsc(y);

%% RECREATE DMA AND WEEK COLUMN
splitDMAWeekCol=[];
for i=1:size(DMAWeek,1)
    splitDMAWeekCol=[splitDMAWeekCol;strsplit(DMAWeek.DMAWeek{i},'|')];
end

splitDMAWeekCol=array2table(splitDMAWeekCol,'VariableNames',{'DMA_MKT_NAME','Week'});
splitDMAWeekCol.Week=datestr(str2double(splitDMAWeekCol.Week));
DMAWeek=[splitDMAWeekCol DMAWeek];

load gong.mat;
soundsc(y);

%% DROP UN-IDENTIFIED DMAs
UnIdntDMA={'ArlingtonVirginia','BIRMINGHAM (ANN AND TUSC)','BenningtonVermont',...
'BethelAlaska','BoulderColorado','BronxNew York','BrookingsSouth Dakota',...
'Brooklyn Park','Brookside','Carson CityNevada','College','ConwayArkansas',...
'Cumberland Hill','DubuqueIowa','DurhamNorth Carolina','Eagan','Eau ClaireWisconsin',...
'FranklinAlabama','FrederickMaryland','Hamilton','Hamilton Square','KearneyNebraska',...
'KenoshaWisconsin','Lakewood','LaramieWyoming','LorainOhio','MerrimackNew Hampshire',...
'Midwest City','Mililani Town','Moore','OFallon','Orchard Homes','Parma',...
'Plymouth','PuebloColorado','QueensNew York','RacineWisconsin','RutlandVermont',...
'SacramentoCalifornia','ShawneeKansas','SitkaAlaska','SpartanburgSouth Carolina',...
'Sunrise Manor','TuscaloosaAlabama','Unknown','WaukeshaWisconsin','West Valley City',...
'Wilmington Manor Gardens','YanktonSouth Dakota','Other Alaska','PALM SPRINGS',...
'Puerto Rico'};
DMAWeekDropped=DMAWeek(~ismember(DMAWeek.DMA_MKT_NAME,UnIdntDMA),:);
DMAWeekDropped.DMAWeek=[];
%% WRITE TABLE

writetable(DMAWeekDropped,'Humana Proof-of-Concept Data3.txt','Delimiter','|');

%% Sanity Test
% A=DMAWeek(strcmp(cellstr(datestr(DMAWeek.Week,'yyyy')),'2013'),{'DMA_MKT_NAME','Week','BrandMedicareMarketSpotTV'});
% B=DATASTRUCT.Brand.MedicarePreAEPCombinedLocal(strcmp(cellstr(datestr(DATASTRUCT.Brand.MedicarePreAEPCombinedLocal.Week,'yyyy')),'2013'),{'DMA_MKT_NAME','Week','SpotTV'});
% 
% A=project1data(strcmp(cellstr(datestr(project1data.Week,'yyyy')),'2013'),{'DMA_MKT_NAME','Week','BrandMedicareMarketSpotTV'});
% 
% A(ismember(A.DMA_MKT_NAME,unique(B.DMA_MKT_NAME)),:);
% nansum(ans.BrandMedicareMarketSpotTV);
% 
% 
% 
% Project1Data(strcmp(Project1Data.DMAWeek,'GREENVILE SPART|735521'),'BrandMedicareMarketSpotTV');
% 
% 
% 
% %% Sanity Test
% 
% A=DMAWeek(strcmp(cellstr(datestr(DMAWeek.Week,'yyyy')),'2014'),...
%     {'DMA_MKT_NAME','Week','DMASpendDR_DIRECTMAIL'});
% B=DATASTRUCT.DRLM.DMASpend(strcmp(cellstr(datestr(...
%     DATASTRUCT.DRLM.DMASpend.Week,'yyyy')),'2014'),...
%     {'DMA_MKT_NAME','Week','DR_DIRECTMAIL'});
% 
% nansum(A{:,[3]})
% nansum(B{:,[3]})
% 
% %% SCRAP WORK
% 
% 
% 
% DMAWeek(ismember(DMAWeek.DMA_MKT_NAME,UnIdntDMA),:);
% ans.Week=[];
% ans.DMAWeek=[];
% ans.CisionSubentity=[];
% grpstats(ans,'DMA_MKT_NAME','nansum');
% 
% 



























