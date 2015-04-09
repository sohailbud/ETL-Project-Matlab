% Do not include market column. Only include 'Week' and variables
function D_Updated = national2DMA(D)

p='C:\Users\Sohail\Dropbox\Humana\Medicare Q1 2015\';
MktCRef=importMarketCrossRef(strcat(p,'Data\ReadIn\MarketCrossReferencebyCounty.csv'));
MktCRef=MktCRef(~strcmp(MktCRef.DMA_MKT_NAME,'Puerto Rico'),:);

%%
D_Updated=national2County(D);
D_Updated=county2DMA(D_Updated);

%% TRANSFORM NATIONAL TO COUNTY
    function D_Updated = national2County(D)
        D_Updated=[];
        D.Week=datenum(D.Week);
        for r=1:size(D,1)
            % Market and year of row in loop
            
            year=str2double(strcat(datestr(D.Week(r),'yyyy'),'06'));
            
            % Sub of MktCRef for market and year in loop
            MktCRef_Sub=MktCRef(ismember(MktCRef.CAL_YR_MTH,year),...
                {'CNTY_NAME','DMA_MKT_NAME','TTL_ELIGIBLE'});
            
            MktCRef_Sub=grpstats(MktCRef_Sub,{'CNTY_NAME','DMA_MKT_NAME'},'mean');
            MktCRef_Sub.Properties.RowNames={};
            MktCRef_Sub.GroupCount=[];
            MktCRef_Sub.perc=MktCRef_Sub.mean_TTL_ELIGIBLE/sum(MktCRef_Sub.mean_TTL_ELIGIBLE);
            
            % Remove Week and Market columns
            D_Sub=D(r,setxor(D.Properties.VariableNames,{'Week'}));
            
            % Multiply percentage of counties in given market to compute
            % variable value for each county
            D_Sub_County=MktCRef_Sub.perc*table2array(D_Sub);
            
            % Rearrange and add necessary columns
            D_Sub_County=array2table(D_Sub_County,'VariableNames',D_Sub.Properties.VariableNames);
            D_Sub_County.Week=repmat(D{r,'Week'},size(D_Sub_County,1),1);
            D_Sub_County=[D_Sub_County MktCRef_Sub(:,{'DMA_MKT_NAME'})];
            
            D_Updated=[D_Updated; D_Sub_County];
            clear D_Sub_County D_Sub MktCRef_Sub
        end
    end
%% TRANSFORM COUNTY TO DMA
%  AGGREGATE BY DMAs
%  Input/Output:Table
    function D_Updated = county2DMA(D_Updated)
        % Groupby DMAs and Dates
        D_Updated=grpstats(D_Updated,{'Week','DMA_MKT_NAME'},'nansum');
        
        % Cleanup
        D_Updated.Properties.RowNames={};
        D_Updated.GroupCount=[];
        VN=D_Updated.Properties.VariableNames;
        for vn=VN
            oldvn=vn{1};
            vn{1}=strrep(vn{1},'nansum_','');
            D_Updated.Properties.VariableNames{oldvn}=vn{1};
        end
    end

end