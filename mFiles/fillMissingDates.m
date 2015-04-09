%% FILL IN MISSING DATES

function d = fillMissingDates(D)
%Continuous week column

if strcmp(unique(cellstr(datestr(D.Week,'ddd'))),'Mon')
    w=min(datenum(D.Week)):7:max(datenum(D.Week));
    w=table(w','VariableName',{'Week'});
    
    D.Week=datenum(D.Week);
    
    try
        cat=unique(D.Cat);
    catch
    end
    
    dma=unique(D.DMA_MKT_NAME);
    
    d={};
    for ii=1:numel(dma)
        di=D(strcmp(D.DMA_MKT_NAME,dma{ii}),:);
        di=outerjoin(w,di,'Type','left','Keys','Week');
        di.Week_di=[];
        di.Week=di.Week_w;
        di.Week_w=[];
        di.DMA_MKT_NAME=repmat(dma(ii),size(di,1),1);
        d=[d;di];
    end
  
    try
        d.Cat=repmat(cat,size(d,1),1);
    catch
    end
    
else
    error('Check the dates to make sure it is Mondays');
end

end

