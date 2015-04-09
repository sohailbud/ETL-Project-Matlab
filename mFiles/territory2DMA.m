function D = territory2DMA(D)

p='C:\Users\Sohail\Dropbox\Humana\Medicare Q1 2015\';
MktCRef=importMarketCrossRef(strcat(p,'Data\ReadIn\MarketCrossReferencebyCounty.csv'));
MktCRef=MktCRef(~strcmp(MktCRef.DMA_MKT_NAME,'Puerto Rico'),:);

%%
D = territory2County(D);
D = county2DMA(D);


%% TRANSFORM TERRITORY TO COUNTY
%  USE PCT_OF_TERRITORY
%  Input/Output:Table
    function D_Updated = territory2County(D)
        %  D -> D_Sub -> D_Sub_County -> D_Updated
        D_Updated=[];
        % Loop over rows of D and convert that territory to counties 
        for r=1:size(D,1)
            % Territory and year of row in loop
            territory=cellstr(D{r,'TERRITORY_NAME'});
            year=str2double(strcat(datestr(cellstr(D{r,'Week'}),'yyyy'),'06'));
            
            % Sub of MktCRef for territory and year in loop
            MktCRef_Sub=MktCRef(ismember(lower(MktCRef.TERRITORY_NAME),lower(territory{1}))&...
                ismember(MktCRef.CAL_YR_MTH,year),...
                {'CAL_YR_MTH','CNTY_NAME','DMA_MKT_NAME','TERRITORY_NAME','PCT_OF_TERRITORY'});
            
            % Check if the percentages add up to 1
            if ~eq(round(sum(MktCRef_Sub.PCT_OF_TERRITORY)),1)
                r
                error('Percentages do not add up to 1')
            end
            
            % Remove Week and TERRITORY_NAME columns
            D_Sub=D(r,setxor(D.Properties.VariableNames,{'Week','TERRITORY_NAME'}));
            
            % Multiply percentage of counties in given territory to compute
            % variable value for each county
            D_Sub_County=MktCRef_Sub.PCT_OF_TERRITORY*table2array(D_Sub);
            
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
    function D = county2DMA(D)
        % Groupby DMAs and Dates
        D=grpstats(D,{'Week','DMA_MKT_NAME'},'nansum');
        
        % Cleanup
        D.Properties.RowNames={};
        D.GroupCount=[];
        VN=D.Properties.VariableNames;
        for vn=VN
            oldvn=vn{1};
            vn{1}=strrep(vn{1},'nansum_','');
            D.Properties.VariableNames{oldvn}=vn{1};
        end
    end

end