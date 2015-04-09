function DRLM = importDirectResponse(p)

path=strcat(p,'DATA\ReadIn\Direct Response');
MktRef = readtable(strcat(p,'Data\ReadIn\MarketCrossReferencebyCounty.csv'));
MktRef = MktRef(~strcmp(MktRef.DMA_MKT_NAME,'Puerto Rico'),:);

%% LOAD DATA
DRLM=loadData(path);

%% UPDATE DR DMA NAMES
DRLM.CallCenterApplDR=updateDRDMANames(DRLM.CallCenterApplDR);
DRLM.CallsDR=updateDRDMANames(DRLM.CallsDR);
DRLM.DMASpendDR=updateDRDMANames(DRLM.DMASpendDR);
DRLM.EligiblesDR=updateDRDMANames(DRLM.EligiblesDR);
DRLM.LeadsDR=updateDRDMANames(DRLM.LeadsDR);
DRLM.OnlineApplDR=updateDRDMANames(DRLM.OnlineApplDR);

%% CONVERT NationalSpendDR FROM NATIONAL TO DMA
DRLM.NationalSpendDR=national2DMA(DRLM.NationalSpendDR);

%% CONVERT LM FROM TERRITORY TO DMA
DRLM.CallCenterApplLM=territory2DMA(DRLM.CallCenterApplLM);
DRLM.CallsLM=territory2DMA(DRLM.CallsLM);
DRLM.DMASpendLM=territory2DMA(DRLM.DMASpendLM);
DRLM.EligiblesLM=territory2DMA(DRLM.EligiblesLM);
DRLM.LeadsLM=territory2DMA(DRLM.LeadsLM);
DRLM.OnlineApplLM=territory2DMA(DRLM.OnlineApplLM);


%% FILL MISSING DATES
for field = fieldnames(DRLM)'
    DRLM.(field{1})=fillMissingDates(DRLM.(field{1}));
end

%% HRIZONTAL CONCATENATE DR & LM
DRLM=horizontalConcatDRLM(DRLM);

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% LOAD DATA
    function s = loadData(path)
        s=struct;
        for file = dir(path)'
            if ~file.isdir
                d=readtable(strcat(path,'\',file.name),'ReadVariableNames',true,...
                    'HeaderLines',1);
                d=d(strcmp(d.LineOfBusiness,'HUMANA MEDICARE'),:);
                d.LineOfBusiness=[];
                try d.Properties.VariableNames{'DMAName'}='DMA_MKT_NAME'; catch; end
                try d.Properties.VariableNames{'TerritoryName'}='TERRITORY_NAME'; catch; end
                try d.TerritoryCode=[]; catch; end
               
                % Drop 'PALM SPRINGS CA' DMA data
                try d=d(~strcmp(d.DMA_MKT_NAME,'PALM SPRINGS CA'),:); catch; end
                % Drop 2015 data     
                d=d(~strcmp(cellstr(datestr(d.Week,'yyyy')),'2015'),:);
                % Drop '{'PUERTO RICO'}' TERRITORY_NAME
                try d=d(~strcmp(d.TERRITORY_NAME,'PUERTO RICO'),:); catch; end
                
                f=file.name(1:end-4);
                f(f==' ' | f=='-')=[];
                s.(f)=d;
                clear d f
            end
        end
    end

%% UPDATE DMA NAMES
%  TERRITORY NAMES IN LM DATA ALREADY MATCH (CHECKED)
    function D = updateDRDMANames(D)
        [~,loc]=ismember(D.DMACode,MktRef.DMA_CD);
        D.DMA_MKT_NAME=MktRef{loc,'DMA_MKT_NAME'};
        D.DMACode=[];
    end

%% HRIZONTAL CONCATENATE DR LM
    function s = horizontalConcatDRLM(s)
        for field=fieldnames(s)'
            if ~isempty(strfind(field{1},'LM'))
                
                dr=s.(strcat(field{1}(1:end-2),'DR'));
                lm=s.(strcat(field{1}(1:end-2),'LM'));
                
                % Convert to datenum
                dr.Week=datenum(dr.Week);
                lm.Week=datenum(lm.Week);
                
                % Create common Week and DMA table
                DRLM=[dr(:,{'DMA_MKT_NAME','Week'});lm(:,{'DMA_MKT_NAME','Week'})];
                DRLM=unique(DRLM);
                
                % Left join DR and LM on common table
                DRLM=outerjoin(DRLM,dr,'Keys',{'DMA_MKT_NAME','Week'});
                DRLM.Properties.VariableNames{'DMA_MKT_NAME_DRLM'}='DMA_MKT_NAME';
                DRLM.Properties.VariableNames{'Week_DRLM'}='Week';
                DRLM=outerjoin(DRLM,lm,'Keys',{'DMA_MKT_NAME','Week'});
                DRLM.Properties.VariableNames{'DMA_MKT_NAME_DRLM'}='DMA_MKT_NAME';
                DRLM.Properties.VariableNames{'Week_DRLM'}='Week';
                DRLM(:,{'DMA_MKT_NAME_dr','Week_dr','DMA_MKT_NAME_lm','Week_lm'})=[];
                
                % Remove individual DR LM files and store new
                s=rmfield(s,strcat(field{1}(1:end-2),'DR'));
                s=rmfield(s,field{1});
                s.(field{1}(1:end-2))=DRLM;
                clear DRLM dr lm
                
            end
        end
    end

end