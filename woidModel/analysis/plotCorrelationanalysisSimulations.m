% plot correlation analysis

% issues/to-do:

clear
close all

exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',10,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',12,...
    'LineWidth',1,...
    'Renderer','opengl');

% define functions for grpstats
mad1 = @(x) mad(x,1); % median absolute deviation
% alternatively could use boxplot-style confidence intervals on the mean,
% which are 1.57*iqr/sqrt(n)
distBinwidth = 0.01; % in units of mm
simulations = {'DA609_noflux','N2_noflux','DA609_noflux_slowingNodesAll',...
    'DA609_noflux_lennardjones1e-04'};
nSims = length(simulations);
plotColors = lines(nSims);
trackedNodesNames = {'head','body'};
trackedNodesDict = containers.Map({'head','body'},{1:5; 1:49});% which nodes to calculate the tracking stats from, to compare eg with pharynx labeled expmntal data
for trackedNodesName = trackedNodesNames
    trackedNodes = trackedNodesDict(trackedNodesName{1});
    for simCtr = 1:nSims % can be parfor
        filenames = {[simulations{simCtr}]};
        speedFig = figure; hold on
        dircorrFig = figure; hold on
        velcorrFig = figure; hold on
        poscorrFig = figure; hold on
        %% load data
        numFiles = length(filenames);
        for fileCtr = 1:numFiles
            filename = ['../results/' filenames{fileCtr} '.mat'];
            thisFile = load(filename);
            maxNumFrames = size(thisFile.xyarray,4);
            burnIn = round(0.1*maxNumFrames);
            numFrames = maxNumFrames-burnIn; %round(maxNumFrames*this.dT/this.saveevery/5);
            framesAnalyzed = burnIn + randperm(maxNumFrames - burnIn,numFrames); % randomly sample frames without replacement
            
            %% calculate stats
            [s_med,s_mad, corr_o_med,corr_o_mad, corr_v_med,corr_v_mad, gr,distBins] = ...
    correlationanalysisSimulations(thisFile,trackedNodes,distBinwidth,framesAnalyzed);
            %% plot data
            bins = (0:numel(s_med)-1).*distBinwidth;
            boundedline(bins,s_med,[s_mad, s_mad],...
                'alpha',speedFig.Children,'cmap',plotColors(simCtr,:))
            bins = (0:numel(corr_o_med)-1).*distBinwidth;
            boundedline(bins,corr_o_med,[corr_o_mad, corr_o_mad],...
                'alpha',dircorrFig.Children,'cmap',plotColors(simCtr,:))
            boundedline(bins,corr_v_med,[corr_v_mad, corr_v_mad],...
                'alpha',velcorrFig.Children,'cmap',plotColors(simCtr,:))
            boundedline(distBins(2:end)-distBinwidth/2,mean(gr,2),...
                [nanstd(gr,0,2) nanstd(gr,0,2)]./sqrt(numFrames),...
                'alpha',poscorrFig.Children,'cmap',plotColors(simCtr,:))
        end
        %% format and export figures
        for figHandle = [speedFig, dircorrFig, velcorrFig, poscorrFig] % common formating for both figures
            title(figHandle.Children,[simulations{simCtr} ' simulation, ' trackedNodesName{1} ' tracked'],...
                'FontWeight','normal','Interpreter','none');
            set(figHandle,'PaperUnits','centimeters')
        end
        %
        speedFig.Children.XLim = [0 2];
        ylabel(speedFig.Children,'speed (mm/s)')
        xlabel(speedFig.Children,'distance to nearest neighbour (mm)')
        speedFig.Children.Box = 'on';
        speedFig.Children.XDir = 'reverse';
        figurename = ['speedvsneighbourdistance_' simulations{simCtr} '_' trackedNodesName{1}];
        exportfig(speedFig,[figurename '.eps'],exportOptions)
        system(['epstopdf ' figurename '.eps']);
        system(['rm ' figurename '.eps']);
        %
        dircorrFig.Children.YLim = [-1 1];
        dircorrFig.Children.XLim = [0 1];
        ylabel(dircorrFig.Children,'directional correlation')
        xlabel(dircorrFig.Children,'distance r (mm)')
        figurename = ['dircrosscorr' simulations{simCtr} '_' trackedNodesName{1}];
        exportfig(dircorrFig,[figurename '.eps'],exportOptions)
        system(['epstopdf ' figurename '.eps']);
        system(['rm ' figurename '.eps']);
        %
%         velcorrFig.Children.YLim = [-1 1];
        velcorrFig.Children.XLim = [0 1];
        ylabel(velcorrFig.Children,'velocity correlation')
        xlabel(velcorrFig.Children,'distance r (mm)')
        figurename = ['velcrosscorr' simulations{simCtr} '_' trackedNodesName{1}];
        exportfig(velcorrFig,[figurename '.eps'],exportOptions)
        system(['epstopdf ' figurename '.eps']);
        system(['rm ' figurename '.eps']);
        %
        poscorrFig.Children.XLim = [0 2];
        ylabel(poscorrFig.Children,'positional correlation g(r)')
        xlabel(poscorrFig.Children,'distance r (mm)')
        figurename = ['radialdistributionfunction_' simulations{simCtr} '_' trackedNodesName{1}];
        exportfig(poscorrFig,[figurename '.eps'],exportOptions)
        system(['epstopdf ' figurename '.eps']);
        system(['rm ' figurename '.eps']);
    end
end