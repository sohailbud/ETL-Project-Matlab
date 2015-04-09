function MA = importMemberActivity(p)

path=strcat(p,'DATA\ReadIn\Member Activity\DMA Sales-Terms by Week-v.2.0.txt');

%%
MA=readtable(path,'Delimiter','\t');
MA(ismember(MA.DMA_MKT_NAME,'Unknown'),:)=[];
MA.DMA_MKT_NAME=strrep(MA.DMA_MKT_NAME,',','-');
MA.WEEK_NBR=[];
MA.WEEK_END=[];
MA.Properties.VariableNames{'WEEK_START'}='Week';

