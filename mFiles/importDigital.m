
function TransformedD = importDigital(p)

path=strcat(p,'DEV\MATLAB\ETL\DATA\Digital');
GoogleMktRef=readtable(strcat(p,'DATA\ReadIn\GoogleMktRef.csv'));
MSNMktRef=readtable(strcat(p,'DATA\ReadIn\MSNMktRef.csv'));

%% LOAD & CONCAT DATA
for file=dir(path)'
    if ~file.isdir
        load(strcat(path,'\',file.name));
    end
end
clear file path

Google = [GoogleMedicare;GooglePDP];
clear GoogleMedicare GooglePDP

MSN = [MSNMedicare; MSNPDP];
clear MSNMedicare MSNPDP

%% UPDATE Google DMA NAMES
% Create ref using city and region for missing metro areas
emptyCells=find(cellfun(@isempty,Google.Metroarea));
Google.Metroarea(emptyCells)=strcat(Google.City(emptyCells),Google.Region(emptyCells),'-CityRegionREF');
clear emptyCells;

% Use GoogleMktRef to update to standard DMA names
[logic,loc]=ismember(Google.Metroarea,GoogleMktRef.Original);
Google.Metroarea(logic)=GoogleMktRef{loc(logic),'New'};
Google=Google(logic,:);
clear GoogleMktRef logic loc

% Rearrange & delete unnecessary
Google.DMA_MKT_NAME=Google.Metroarea;
Google(:,setxor(Google.Properties.VariableNames,{'Week','DMA_MKT_NAME',...
    'Clicks','Impressions','Cost'}))=[];
Google=Google(:,{'Week','DMA_MKT_NAME','Clicks','Impressions','Cost'});

%% UPDATE MSN DMA NAMES
% Use MSNMktRef to update to standard DMA names
[logic,loc]=ismember(MSN.Metroarea,MSNMktRef.Original);
MSN.Metroarea(logic)=MSNMktRef{loc(logic),'New'};
MSN=MSN(logic,:);
clear MSNMktRef logic loc

% Rearrange & delete unnecessary
MSN.DMA_MKT_NAME=MSN.Metroarea;
MSN.Cost=MSN.Spend;
MSN(:,setxor(MSN.Properties.VariableNames,{'Week','DMA_MKT_NAME',...
    'Clicks','Impressions','Cost'}))=[];
MSN=MSN(:,{'Week','DMA_MKT_NAME','Clicks','Impressions','Cost'});

% Set RawD before aggregation
RawD=[Google;MSN];

%% FIX MSN DATES
MSN.Days=cellstr(datestr(MSN.Week,'dddd'));
MSN.Week=datenum(MSN.Week);
MSN.Week(strcmp(MSN.Days,'Sunday'))=MSN.Week(strcmp(MSN.Days,'Sunday'))+1;
MSN.Days=[];

%% CONCAT & AGGREGATE BY WEEK AND DMA NAMES 
TransformedD=[Google;MSN];
clear Google MSN
TransformedD=grpstats(TransformedD,{'Week','DMA_MKT_NAME'},'nansum');

% Rearrange & delete unnecessary
TransformedD.Properties.RowNames={};
TransformedD.Clicks = TransformedD.nansum_Clicks;
TransformedD.Impressions = TransformedD.nansum_Impressions;
TransformedD.Cost = TransformedD.nansum_Cost;
TransformedD(:,setxor(TransformedD.Properties.VariableNames,{'Week','DMA_MKT_NAME',...
    'Clicks','Impressions','Cost'}))=[];

%% FILL MISSING DATES
TransformedD=fillMissingDates(TransformedD);

%% SANITY CHECK
A=varfun(@sum,TransformedD(:,3:end));
B=varfun(@sum, RawD(:,3:end));
sum(table2array(A),1)==sum(table2array(B),1)

end