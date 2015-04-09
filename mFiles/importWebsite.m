function Web = importWebsite(p)

path=strcat(p,'DATA\ReadIn\Website\UniqueVisitors_20140811_20150105.csv');
MktCRef=importMarketCrossRef(strcat(p,'Data\ReadIn\MarketCrossReferencebyCounty.csv'));
MktCRef=MktCRef(~strcmp(MktCRef.DMA_MKT_NAME,'Puerto Rico'),:);

%%
Web = readtable(path);
Web(:,{'x____Date','End'})=[];
Web.Properties.VariableNames{'Start'}='Week';

%% FIX DATES
% Add Jan-1 of each year end of previous year's week
% loop through locations of 1/1
loc=find(~strcmp(cellstr(datestr(Web.Week,'ddd')),'Mon'));
for l=loc'
    %loop through numeric colums for those locations
    for col=setxor(Web.Properties.VariableNames,{'Week'})
        Web(l-1,col)={Web{l-1,col}+Web{l,col}};
    end
end
Web(loc,:)=[];

% Drop 2015 data
Web(ismember(cellstr(datestr(Web.Week,'yyyy')),'2015'),:)=[];

%% JOIN MktCRef Perc. COLUMN WITH DATA BY YEAR
yrs={'2014'};
d=[];
for y=1:numel(yrs)
    
    % MktCRef SUBSET OF GIVEN YEAR & UNIQUE ST_CNTY_FIPS_CD
    MktCRef_yr=MktCRef(MktCRef.CAL_YR_MTH==str2num(strcat(yrs{y},'06')),...
        {'CAL_YR_MTH','CNTY_NAME','DMA_MKT_NAME','TTL_ELIGIBLE'});
    [~,loc,~]=unique(MktCRef_yr.ST_CNTY_FIPS_CD);
    MktCRef_yr=MktCRef_yr(loc,:);
    
    % ADD PERC. COLUMN
    MktCRef_yr.Perc=MktCRef_yr.TTL_ELIGIBLE./sum(MktCRef_yr.TTL_ELIGIBLE);
    MktCRef_yr.Market=repmat({'National'},size(MktCRef_yr,1),1);
    
    % SUBSET OF BRAND BY YEAR
    di=Web(strcmp(cellstr(datestr(Web.Week,'yyyy')),yrs{y}),:);
    di.Market=repmat({'National'},size(di,1),1);
    
    % JOIN COUNTIES TO BRAND DATA
    di=outerjoin(MktCRef_yr,di,'Keys','Market');
    di(:,{'CAL_YR_MTH','ST_CNTY_FIPS_CD','TTL_ELIGIBLE','Market_di','Market_MktCRef_yr'})=[];
    d=[d;di];
    
end
Web=d;
clear d di

% MULTIPLY BY PERC.
col=setxor(Web.Properties.VariableNames,{'DMA_MKT_NAME','Perc','Week'});
for c=1:numel(col)
    Web.(col{c})=Web.Perc.*Web.(col{c});
end
Web.Perc=[];

% GROUPBY DMA & DATES
Web=grpstats(Web,{'DMA_MKT_NAME','Week'},'nansum');
Web.Properties.RowNames={};
Web.GroupCount=[];

%REMOVE LEADING "SUM" FROM VARIABLE NAMES
fn=Web.Properties.VariableNames;
for f=1:numel(fn)
    if ~isempty(strfind(fn{f},'nansum'))
        Web.(fn{f}(8:end))=Web.(fn{f});
        Web.(fn{f})=[];
    end
end

