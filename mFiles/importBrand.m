function Brand = importBrand(p)

path=strcat(p,'DATA\ReadIn\Brand');
BrandMktRef=readtable(strcat(p,'DATA\ReadIn\BrandMktRef.csv'));

%% LOAD DATA
Brand=loadData(path);

%% CONVERT NATIONAL TO DMA
Brand.HumanaBrandNational=national2DMA(Brand.HumanaBrandNational);
Brand.HumanaChallengeNational=national2DMA(Brand.HumanaChallengeNational);
Brand.MedicarePreAEPNational=national2DMA(Brand.MedicarePreAEPNational);

%% UPDATE DMA NAMES AND AGGREGATE
Brand.HumanaBrandLocal=updateDMANamesAggregate(Brand.HumanaBrandLocal);
Brand.MedicarePreAEPCombinedLocal=updateDMANamesAggregate(Brand.MedicarePreAEPCombinedLocal);

%% MedicarePreAEPCombinedLocal DATE FIX
Brand.MedicarePreAEPCombinedLocal=fixMedicarePreAEPCombinedLocalDates(Brand.MedicarePreAEPCombinedLocal);

%% FILL MISSING DATES
for field = fieldnames(Brand)
    Brand.(field{1})=fillMissingDates(Brand.(field{1}));
end

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% LOAD DATA
    function Brand = loadData(path)
        Brand=struct;
        for file = dir(path)'
            if ~file.isdir
                f=file.name(1:end-4);
                f(f==' ' | f==')' | f=='(' | f=='-')=[];
                D=readtable(strcat(path,'\',file.name));
                D.BroadcastMonth = [];
                D.Properties.VariableNames{'BroadcastWeek'}='Week';
                
                if ~isempty(strfind(f,'Local'))
                    D.Properties.VariableNames{'Market'}='DMA_MKT_NAME';
                elseif ~isempty(strfind(f,'National'))
                    D.Market=[];
                end
                
                Brand.(f)=D;
            end
        end
    end

%% UPDATE DMA NAMES and AGGREGATE
    function D = updateDMANamesAggregate(D)
        
        % Change to standard DMA names
        [~,loc]=ismember(D.DMA_MKT_NAME,BrandMktRef.Original);
        D.DMA_MKT_NAME=BrandMktRef{loc,'New'};
        clear logic loc
        
        % Aggregate by week and dma names
        D=grpstats(D,{'Week','DMA_MKT_NAME'},'nansum');
        D.Properties.RowNames={};
        
        % Clean the variables names
        VN=D.Properties.VariableNames;
        for vn=VN
            oldvn=vn{1};
            vn{1}=strrep(vn{1},'nansum_','');
            D.Properties.VariableNames{oldvn}=vn{1};
        end
        D.GroupCount=[];
    end

%% MedicarePreAEPCombinedLocal DATE FIX
%  Change 'Tuesday' entry to 'Monday'
    function D = fixMedicarePreAEPCombinedLocalDates(D)
        D.Days=cellstr(datestr(D.Week,'dddd'));
        D.Week=datenum(D.Week);
        D.Week(strcmp(D.Days,'Tuesday'))=D.Week(strcmp(D.Days,'Tuesday'))-1;
        D.Days=[];
    end

end