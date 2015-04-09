function Cision = importCision(p)
path=strcat(p,'DATA\ReadIn\Cision\Humana data by week Sept - Dec 2014.csv');
CisionMktRef = readtable(strcat(p,'DATA\ReadIn\CisionMktRef.csv'));

%% LOAD DATA
Cision=readtable(path);
Cision(:,{'Year','NewsDate','ArticleCount'})=[];

%% NAME FIXES
Cision.Properties.VariableNames{'WeekBegins'}='Week';
Cision.Properties.VariableNames{'USDMA'}='DMA_MKT_NAME';

%% DROP
% Drop National from DMA_MKT_NAME
Cision=Cision(~ismember(Cision.DMA_MKT_NAME,'National'),:);

% Drop 'Palm Springs CA'
Cision=Cision(~ismember(Cision.DMA_MKT_NAME,'Palm Springs CA'),:);

%% DMA NAME FIX
[~,loc]=ismember(Cision.DMA_MKT_NAME,CisionMktRef.Original);
Cision.DMA_MKT_NAME=CisionMktRef.New(loc);

end