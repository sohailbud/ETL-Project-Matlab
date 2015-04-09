function Agency = importLocalAgencies(p)

path=strcat(p,'DATA\ReadIn\Local Agencies');
MktCRef=importMarketCrossRef(strcat(p,'Data\ReadIn\MarketCrossReferencebyCounty.csv'));
MktCRef=MktCRef(~strcmp(MktCRef.DMA_MKT_NAME,'Puerto Rico'),:);

%% LOAD DATA
Agency=loadData(path);
% Agency=load(strcat(p,'DEV\MATLAB\ETL\DATA\Local Agencies\Agency.mat'));
% Agency=Agency.AGENCY;

%% INSERT NaN FOR MISSING COLUMNS - CONSISTENT VARIABLE NAMES ACROSS AGENCIES
Agency = insertMissingColumnsFixVariableNames(Agency);

%% DROP EMPTY VAR COLUMNS AND ROWS
Agency = dropEmpties(Agency);

%% CONCATENATE AGENCY DATA
Agency = concatAgencies(Agency);

%% COLLECT RAW DATA
AgencyRaw=struct;
AgencyRaw.Gonzalez=Agency.Gonzalez;
AgencyRaw.Vest=Agency.Vest;
AgencyRaw.ViMarc=Agency.ViMarc;
AgencyRaw.Heinrich=Agency.Heinrich;

%% GONZALEZ TRANSFORMATION
Agency.Gonzalez = gonzalezMarket2Territory(Agency.Gonzalez);
Agency.Gonzalez = territory2County(Agency.Gonzalez);
Agency.Gonzalez = county2DMA(Agency.Gonzalez);
Agency.Gonzalez = fillMissingDates(Agency.Gonzalez);

%% Vest TRANSFORMATION
Agency.Vest = marketNameChange(Agency,'Vest');
Agency.Vest = market2County(Agency.Vest);
Agency.Vest = county2DMA(Agency.Vest);
Agency.Vest = fixVestDates(Agency.Vest);
Agency.Vest = fillMissingDates(Agency.Vest);

%% ViMarc TRANSFORMATION
Agency.ViMarc = marketNameChange(Agency,'ViMarc');
Agency.ViMarc = market2County(Agency.ViMarc);
Agency.ViMarc = county2DMA(Agency.ViMarc);
Agency.ViMarc = fixViMarcDates(Agency.ViMarc);
Agency.ViMarc = fillMissingDates(Agency.ViMarc);

%% Heinrich TRANSFORMATION
Agency.Heinrich = marketNameChange(Agency,'Heinrich');
Agency.Heinrich = market2County(Agency.Heinrich);
Agency.Heinrich = county2DMA(Agency.Heinrich);
Agency.Heinrich = fillMissingDates(Agency.Heinrich);

%% SANITY CHECK
sanityCheck(Agency,AgencyRaw)
clear AgencyRaw;

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% LOAD DATA
    function Agency = loadData(path)
        ViMarc=struct;
        Gonzalez=struct;
        Heinrich=struct;
        Vest=struct;
        
        FOLDER=dir(path);
        for folder = FOLDER'
            if folder.isdir && folder.name(1) ~= '.'
                files=dir(strcat(path,'/',folder.name));
                for file = files'
                    if ~file.isdir
                        f=file.name(1:end-4);
                        f(f==' ' | f==')' | f=='(' | f=='-')=[];
                        if strcmp(folder.name,'ViMarc')
                            ViMarc.(f)=readtable(strcat(path,'/',folder.name,'/',file.name),'ReadVariableNames',true);
                        elseif strcmp(folder.name,'Gonzalez')
                            Gonzalez.(f)=readtable(strcat(path,'/',folder.name,'/',file.name),'ReadVariableNames',true);
                        elseif strcmp(folder.name,'Heinrich')
                            Heinrich.(f)=readtable(strcat(path,'/',folder.name,'/',file.name),'ReadVariableNames',true);
                        elseif strcmp(folder.name,'Vest')
                            Vest.(f)=readtable(strcat(path,'/',folder.name,'/',file.name),'ReadVariableNames',true);
                        end
                    end
                end
            end
        end
        
        Agency=struct('ViMarc',ViMarc,'Gonzalez',Gonzalez,'Heinrich',Heinrich,'Vest',Vest);
        clear ViMarc Gonzalez Heinrich Vest file files folder FOLDER path f
    end

%% INSERT NaN FOR MISSING COLUMNS - CONSISTENT VARIABLE NAMES ACROSS AGENCIES
    function Agency = insertMissingColumnsFixVariableNames(Agency)
        VNames=[]; % Create unique list of variable names across all data
        % Change variable names to make it consistent across all data
        for fields = fieldnames(Agency)'
            for field = fieldnames(Agency.(fields{1}))'
                d=Agency.(fields{1}).(field{1});
                try d.Properties.VariableNames{'DIGITAL'}='Digital'; catch; end
                try d.Properties.VariableNames{'DIRECTMAIL'}='DirectMail'; catch; end
                try d.Properties.VariableNames{'DM'}='DirectMail'; catch; end
                try d.Properties.VariableNames{'OUTDOOR'}='Outdoor'; catch; end
                try d.Properties.VariableNames{'PRINT'}='Print'; catch; end
                try d.Properties.VariableNames{'RADIO'}='Radio'; catch; end
                try d.Properties.VariableNames{'SPONSORSHIPS'}='Sponsorships'; catch; end
                try d.Properties.VariableNames{'WEEKOF'}='Week'; catch; end
                try d.Properties.VariableNames{'WeekOf'}='Week'; catch; end
                try d.Properties.VariableNames{'WkOf'}='Week'; catch; end
                Agency.(fields{1}).(field{1})=d;        
                VNames=[VNames;d.Properties.VariableNames'];
            end
        end
        
        VNames=unique(VNames);
        
        % Create NaN columns for missing variables 
        for fields = fieldnames(Agency)'
            for field = fieldnames(Agency.(fields{1}))'
                d=Agency.(fields{1}).(field{1});
                MissingVNames=setxor(VNames,d.Properties.VariableNames);
                Missingd=cell2table(num2cell(nan(size(d,1),numel(MissingVNames))),...
                    'VariableNames',MissingVNames');
                d=[d Missingd];
                
                Agency.(fields{1}).(field{1})=d;
                clear d
            end
        end
    end

%% DROP EMPTY VAR COLUMNS AND ROWS
    function Agency = dropEmpties(Agency)
        for fields = fieldnames(Agency)'
            for field = fieldnames(Agency.(fields{1}))'
                % Drop empty var columns and empty rows
                d=Agency.(fields{1}).(field{1});
                
                
                for vn = d.Properties.VariableNames
                    if ~isempty(strfind(vn{1},'Var'))
                        d.(vn{1})=[];   %drop empty columns
                    end
                end
                d=d(sum(ismissing(d(:,[1 2])),2)==0,:); %drop empty rows
                
                
                Agency.(fields{1}).(field{1})=d;
            end
        end
    end

%% CONCATENATE AGENCY DATA
    function Agency = concatAgencies(Agency)
        for fields = fieldnames(Agency)'
            D=[];
            for field = fieldnames(Agency.(fields{1}))'
                d=Agency.(fields{1}).(field{1});
                D=[D;d]; % Vertically concatenate agencies
            end
            Agency.(fields{1})=D;
        end
    end

%% GONZALEZ: TRANSFORM FROM GONZALEZ (MARKET) TO TERRITORY 
%  USE TTL_TERRITORY_ELIGIBLE
%  Input/Output: GONZALEZ (Table)
    function GONZALEZ_Updated = gonzalezMarket2Territory(GONZALEZ)
        Gonzalez2Territory=readtable(strcat(p,'Data\ReadIn\Gonzalez2Territory.csv'));

        % GONZALEZ -> GONZALEZ_Sub -> GONZALEZ_Territory_Sub -> GONZALEZ_Updated_fn
        % -> GONZALEZ_Updated
        % Clean Gonzalez Market column
        GONZALEZ.Market=strtrim(GONZALEZ.Market);
        GONZALEZ.Market=strrep(GONZALEZ.Market,' ','_');
        GONZALEZ.Market=strrep(GONZALEZ.Market,'-','_');

        fn=unique(GONZALEZ.Market);
        years=unique(cellstr(datestr(GONZALEZ.Week,'yyyy')));
        
        % Loop through each year and Gonzalez's market
        GONZALEZ_Updated=[];
        for y = 1:numel(years)
            GONZALEZ_Updated_fn=[];
            for n = 1:numel(fn)
                % Using Gonzalez2Territory file, filter on territory names
                % in MktCRef file. Find average of each territory and
                % computer percentages by calculating ratios of territory's
                % mean in that group
                MktCRef_Sub=MktCRef(ismember(MktCRef.TERRITORY_NAME,Gonzalez2Territory.(fn{n}))&...
                    ismember(MktCRef.CAL_YR_MTH,str2double(strcat(years{y},'06'))),...
                    {'CAL_YR_MTH','TERRITORY_NAME','TTL_TERRITORY_ELIGIBLE'});
                MktCRef_Sub=grpstats(MktCRef_Sub,{'CAL_YR_MTH','TERRITORY_NAME'},'mean');
                MktCRef_Sub.Ratio=MktCRef_Sub.mean_TTL_TERRITORY_ELIGIBLE/sum(MktCRef_Sub.mean_TTL_TERRITORY_ELIGIBLE);
                
                % Create a sub matrix for year and market in loop
                GONZALEZ_Sub=GONZALEZ(ismember(GONZALEZ.Market,fn{n})&...
                    ismember(datestr(GONZALEZ.Week,'yyyy'),years(y)),...
                    setxor(GONZALEZ.Properties.VariableNames,{'Market'}));
                
                % Loop over the sub matrix, row at a time, and compute
                % ratios of variables for individual territories
                GONZALEZ_Territory_Sub=[];
                for i=1:size(GONZALEZ_Sub,1)
                    GONZALEZ_Territory_Sub=[GONZALEZ_Territory_Sub;...
                        MktCRef_Sub.Ratio*table2array(GONZALEZ_Sub(i,...
                        setxor(GONZALEZ_Sub.Properties.VariableNames,{'Week'})))];
                end
                
                % Add necessary columns vertically concatenate Sub matrix for individual territories
                GONZALEZ_Territory_Sub=array2table(num2cell(GONZALEZ_Territory_Sub),'VariableNames',...
                    setxor(GONZALEZ_Sub.Properties.VariableNames,{'Week'}));
                GONZALEZ_Territory_Sub.TERRITORY_NAME=repmat(MktCRef_Sub.TERRITORY_NAME,...
                    size(GONZALEZ_Sub,1),1);
                GONZALEZ_Territory_Sub.Week=...
                    reshape(repmat(GONZALEZ_Sub.Week',numel(MktCRef_Sub.Ratio),1),1,[])';
                
                GONZALEZ_Updated_fn=[GONZALEZ_Updated_fn;GONZALEZ_Territory_Sub];
                clear GONZALEZ_Territory_Sub GONZALEZ_Sub
            end
            GONZALEZ_Updated=[GONZALEZ_Updated;GONZALEZ_Updated_fn];
            clear GONZALEZ_Updated_fn
        end
    end

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
            MktCRef_Sub=MktCRef(ismember(MktCRef.TERRITORY_NAME,territory{1})&...
                ismember(MktCRef.CAL_YR_MTH,year),...
                {'CAL_YR_MTH','CNTY_NAME','DMA_MKT_NAME','TERRITORY_NAME','PCT_OF_TERRITORY'});
            
            % Check if the percentages add up to 1
            if ~eq(round(sum(MktCRef_Sub.PCT_OF_TERRITORY)),1)
                error('Percentages do not add up to 1')
                break
            end
            
            % Remove Week and TERRITORY_NAME columns
            D_Sub=D(r,setxor(D.Properties.VariableNames,{'Week','TERRITORY_NAME'}));
            
            % Multiply percentage of counties in given territory to compute
            % variable value for each county
            D_Sub_County=MktCRef_Sub.PCT_OF_TERRITORY*cell2mat(table2array(D_Sub));
            
            % Rearrange and add necessary columns
            D_Sub_County=array2table(D_Sub_County,'VariableNames',D_Sub.Properties.VariableNames);
            D_Sub_County.Week=repmat(D{r,'Week'},size(D_Sub_County,1),1);
            D_Sub_County=[D_Sub_County MktCRef_Sub(:,{'DMA_MKT_NAME'})];
            
            D_Updated=[D_Updated; D_Sub_County];
            clear D_Sub_County D_Sub MktCRef_Sub
        end
    end

%% TRANSFORM MARKET TO COUNTY
%  USE PCT_OF_MARKET
%  Input/Output:Table
    function D_Updated = market2County(D)
        %  D -> D_Sub -> D_Sub_County -> D_Updated
        D_Updated=[];
        for r=1:size(D,1)
            % Market and year of row in loop
            market=cellstr(D{r,'Market'});
            year=str2double(strcat(datestr(cellstr(D{r,'Week'}),'yyyy'),'06'));
            
            % Sub of MktCRef for market and year in loop
            MktCRef_Sub=MktCRef(ismember(MktCRef.MARKET_NAME,market{1})&...
                ismember(MktCRef.CAL_YR_MTH,year),...
                {'CAL_YR_MTH','CNTY_NAME','DMA_MKT_NAME','MARKET_NAME','PCT_OF_MARKET'});
            
            % Check if the percentages add up to 1
            if ~eq(round(sum(MktCRef_Sub.PCT_OF_MARKET)),1)
                'ERROR'
                break
            end
            
            % Remove Week and Market columns
            D_Sub=D(r,setxor(D.Properties.VariableNames,{'Week','Market'}));
            
            % Multiply percentage of counties in given market to compute
            % variable value for each county
            D_Sub_County=MktCRef_Sub.PCT_OF_MARKET*table2array(D_Sub);
                      
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

%% Vest ViMarc Heinrich MARKET NAME CHANGE TO MATCH MktCRef FILE
%  Input/Output:<Structure,Field Name>/Table
    function D = marketNameChange(Agency,agencyName)
        D=Agency.(agencyName);
        Vest_ViMarc_Heinrich_MarketNames=readtable(strcat(p,'Data\ReadIn\Vest_ViMarc_Heinrich_MarketNames.csv'));
               
        D.Market=strtrim(D.Market);
        MarketName=unique(D.Market);

        % Loop through market names and change it with new names to match
        % MktCRef file
        for i=1:numel(MarketName)
            loc = ismember(Vest_ViMarc_Heinrich_MarketNames.(strcat(agencyName,'_Original')),MarketName{i});
            D.Market=strrep(D.Market,MarketName{i},Vest_ViMarc_Heinrich_MarketNames.(strcat(agencyName,'_New')){loc});
        end
    end

%% Vest DATE FIX
%  Change 'Tuesday LA 4/23/2013' entry to 'Monday'
    function D = fixVestDates(D)
        D.Days=cellstr(datestr(D.Week,'dddd'));
        D.Week=datenum(D.Week);
        D.Week(strcmp(D.Days,'Tuesday'))=D.Week(strcmp(D.Days,'Tuesday'))-1;
        D.Days=[];
    end

%% ViMarc DATE FIX
%  Change 'Sundays' to following 'Monday'
    function D = fixViMarcDates(D)
        D.Days=cellstr(datestr(D.Week,'dddd'));
        D.Week=datenum(D.Week);
        D.Week(strcmp(D.Days,'Sunday'))=D.Week(strcmp(D.Days,'Sunday'))+1;
        D.Days=[];
    end

%% SANITY CHECK
    function sanityCheck(Agency,AgencyRaw)
        for field=fieldnames(Agency)'
            VN=Agency.(field{1}).Properties.VariableNames;
            for vn=VN
                if ~strcmp(vn{1},'Week') && ~strcmp(vn{1},'DMA_MKT_NAME')
                    if round(nansum(Agency.(field{1}).(vn{1})))~=...
                            round(nansum(AgencyRaw.(field{1}).(vn{1})))
                        error('something is not adding up')
                    end
                end
            end
        end
    end

end



