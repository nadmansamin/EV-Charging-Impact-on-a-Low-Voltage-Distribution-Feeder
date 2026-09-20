function EV_Grid_Impact_App
% =========================================================================
%  EV CHARGING IMPACT ON A LOW VOLTAGE DISTRIBUTION FEEDER
%  A MATLAB GUI application
%
%  Author : Nadman
%  Course : MATLAB / Simulation Mini-Project
%  Dept   : Electrical and Electronic Engineering, IUT
%
%  HOW TO RUN:
%     1. Put this file in a folder.
%     2. In MATLAB command window type:  EV_Grid_Impact_App
%     3. The app window opens. Requires MATLAB R2018b or newer.
%
%  WHAT IT DOES:
%     Simulates a small residential feeder fed by one distribution
%     transformer. Each house has a daily base load. Some houses own an
%     electric vehicle. The app compares two EV charging strategies over
%     24 hours:
%          (a) Uncoordinated charging - every EV plugs in at evening peak
%          (b) Coordinated charging    - EV charging staggered overnight
%     and reports transformer loading and the voltage seen by the last
%     house on the feeder.
% =========================================================================

%% ------------------------- shared variables ----------------------------
S   = struct();          % holds all graphics handles
res = struct();          % holds simulation results
res.Uncoordinated = [];
res.Coordinated   = [];

buildUI();

% =========================================================================
%                              USER INTERFACE
% =========================================================================
    function buildUI()

        S.fig = uifigure('Name', ...
            'EV Charging Impact on Distribution Grid  |  IUT EEE', ...
            'Position',[80 60 1120 700], ...
            'Color',[0.94 0.96 0.99]);

        S.tg = uitabgroup(S.fig,'Position',[10 10 1100 680]);

        tab1 = uitab(S.tg,'Title','1 - Overview');
        tab2 = uitab(S.tg,'Title','2 - System Setup');
        tab3 = uitab(S.tg,'Title','3 - Simulation');
        tab4 = uitab(S.tg,'Title','4 - Results');

        buildOverviewTab(tab1);
        buildSetupTab(tab2);
        buildSimTab(tab3);
        buildResultsTab(tab4);

        drawDiagram();
    end

% ------------------------------ TAB 1 -----------------------------------
    function buildOverviewTab(tab)

        uilabel(tab,'Position',[40 580 1000 50], ...
            'Text','EV Charging Impact on a Distribution Feeder', ...
            'FontSize',26,'FontWeight','bold', ...
            'FontColor',[0.05 0.22 0.45]);

        uilabel(tab,'Position',[40 550 1000 25], ...
            'Text',['A MATLAB GUI tool for studying voltage drop and ' ...
                    'transformer overloading caused by home EV charging'], ...
            'FontSize',14,'FontColor',[0.30 0.30 0.30]);

        txt = { ...
 'PROBLEM'
 'Electric vehicles are entering residential areas faster than the low voltage'
 'distribution network is being upgraded. A home charger draws roughly 3.3 kW,'
 'which is about the same as two or three ordinary households combined. When'
 'several owners return from work and plug in at the same evening hour, two'
 'problems appear at once:'
 ''
 '   1. The distribution transformer can be pushed beyond its kVA rating.'
 '   2. The voltage at the far end of the feeder sags below the allowed limit.'
 ''
 'METHOD USED IN THIS APP'
 'The feeder is modelled as a radial line. Every house draws a base load that'
 'follows a typical daily residential curve, plus an EV charging load if that'
 'house owns a vehicle. For each hour of the day the app computes:'
 ''
 '   Total demand       P_total(h) = sum of all house loads at hour h'
 '   Transformer load   Loading(%) = P_total / S_rated x 100'
 '   Segment current    I_k = (downstream power) / V_nominal'
 '   Voltage drop       dV_k = I_k x R_segment'
 '   House voltage      V_n = V_nominal - sum of all upstream drops'
 ''
 'The last house on the feeder always experiences the worst voltage, so it is'
 'used as the critical monitoring point.'
 ''
 'TWO CHARGING STRATEGIES COMPARED'
 '   Uncoordinated : every EV starts charging at the same evening peak hour.'
 '   Coordinated   : EV start times are staggered through the off peak night'
 '                   hours so that only one or two vehicles charge together.'
 ''
 'OUTCOME'
 'The app shows that the same number of vehicles can be supplied by the same'
 'transformer without any reinforcement, purely by shifting when they charge.'
 'This is the basic principle behind smart charging and demand side management.'
 ''
 'HOW TO USE'
 '   Tab 2 : set the feeder data and choose which houses own an EV.'
 '   Tab 3 : press Run Simulation, then press Animate for the demonstration.'
 '   Tab 4 : read the numerical comparison and the verdict.'
            };

        ta = uitextarea(tab,'Position',[40 40 1010 495], ...
            'Value',txt,'Editable','off','FontName','Consolas', ...
            'FontSize',12.5,'BackgroundColor',[1 1 1]);
        S.aboutBox = ta;
    end

% ------------------------------ TAB 2 -----------------------------------
    function buildSetupTab(tab)

        % ---------- left panel : numeric inputs ----------
        p = uipanel(tab,'Title','Feeder and Transformer Data', ...
            'Position',[20 250 430 380],'FontWeight','bold', ...
            'FontSize',13,'BackgroundColor',[1 1 1]);

        lbls = { 'Number of houses on feeder', ...
                 'Peak base load per house  (kW)', ...
                 'EV charger rating  (kW)', ...
                 'EV charging duration  (hours)', ...
                 'Transformer rating  (kVA)', ...
                 'Nominal supply voltage  (V)', ...
                 'Resistance per line segment  (ohm)', ...
                 'Allowed voltage tolerance  (%)' };

        defs = [5 1.5 3.3 4 25 230 0.05 5];
        S.inp = gobjects(1,numel(defs));

        y = 315;
        for k = 1:numel(lbls)
            uilabel(p,'Position',[15 y 260 22],'Text',lbls{k}, ...
                'FontSize',12);
            S.inp(k) = uieditfield(p,'numeric','Position',[290 y 120 24], ...
                'Value',defs(k),'FontSize',12);
            y = y - 38;
        end

        S.inp(1).ValueChangedFcn = @(~,~) rebuildHouseTable();
        S.inp(1).Limits = [2 12];
        S.inp(1).RoundFractionalValues = 'on';

        % ---------- right panel : per house EV ownership ----------
        p2 = uipanel(tab,'Title','EV Ownership  (tick the houses that own an EV)', ...
            'Position',[470 250 300 380],'FontWeight','bold', ...
            'FontSize',13,'BackgroundColor',[1 1 1]);

        S.evTable = uitable(p2,'Position',[15 15 270 330], ...
            'ColumnName',{'House','Owns EV'}, ...
            'ColumnEditable',[false true], ...
            'ColumnWidth',{100 120},'FontSize',12);
        rebuildHouseTable();
        S.evTable.CellEditCallback = @(~,~) drawDiagram();

        % ---------- charging schedule panel ----------
        p3 = uipanel(tab,'Title','Charging Schedule Settings', ...
            'Position',[790 250 290 380],'FontWeight','bold', ...
            'FontSize',13,'BackgroundColor',[1 1 1]);

        uilabel(p3,'Position',[15 310 260 22], ...
            'Text','Uncoordinated start hour (0-23)','FontSize',12);
        S.peakStart = uieditfield(p3,'numeric','Position',[15 285 100 24], ...
            'Value',18,'Limits',[0 23],'RoundFractionalValues','on');

        uilabel(p3,'Position',[15 240 260 22], ...
            'Text','Coordinated start hour (0-23)','FontSize',12);
        S.offStart = uieditfield(p3,'numeric','Position',[15 215 100 24], ...
            'Value',22,'Limits',[0 23],'RoundFractionalValues','on');

        uilabel(p3,'Position',[15 170 260 22], ...
            'Text','Stagger between EVs (hours)','FontSize',12);
        S.stagger = uieditfield(p3,'numeric','Position',[15 145 100 24], ...
            'Value',2,'Limits',[0 6],'RoundFractionalValues','on');

        uibutton(p3,'Position',[15 60 255 40], ...
            'Text','Update Single Line Diagram','FontSize',13, ...
            'BackgroundColor',[0.20 0.45 0.75],'FontColor','w', ...
            'ButtonPushedFcn',@(~,~) drawDiagram());

        % ---------- single line diagram ----------
        S.axDiag = uiaxes(tab,'Position',[20 20 1060 215]);
        title(S.axDiag,'Single Line Diagram of the Feeder');
    end

    function rebuildHouseTable()
        N = round(S.inp(1).Value);
        old = S.evTable.Data;
        flags = false(N,1);
        if istable(old) && ~isempty(old)
            m = min(N,height(old));
            flags(1:m) = old.Owns_EV(1:m);
        else
            flags(min(3,N):N) = true;    % default: last few houses own EVs
        end
        T = table((1:N)', flags, 'VariableNames',{'House','Owns_EV'});
        S.evTable.Data = T;
        drawDiagram();
    end

% ------------------------------ TAB 3 -----------------------------------
    function buildSimTab(tab)

        uibutton(tab,'Position',[25 590 200 45],'Text','RUN SIMULATION', ...
            'FontSize',15,'FontWeight','bold', ...
            'BackgroundColor',[0.10 0.55 0.25],'FontColor','w', ...
            'ButtonPushedFcn',@(~,~) onRun());

        uibutton(tab,'Position',[240 590 200 45],'Text','ANIMATE 24 HOURS', ...
            'FontSize',15,'FontWeight','bold', ...
            'BackgroundColor',[0.75 0.40 0.05],'FontColor','w', ...
            'ButtonPushedFcn',@(~,~) onAnimate());

        S.status = uilabel(tab,'Position',[460 590 600 45], ...
            'Text','Status : ready. Press Run Simulation.', ...
            'FontSize',13,'FontColor',[0.25 0.25 0.25]);

        S.axLoad = uiaxes(tab,'Position',[20 300 530 275]);
        S.axVolt = uiaxes(tab,'Position',[560 300 520 275]);
        S.axBar  = uiaxes(tab,'Position',[20 20 530 265]);
        S.axProf = uiaxes(tab,'Position',[560 20 520 265]);

        title(S.axLoad,'Transformer Loading over 24 Hours');
        title(S.axVolt,'Voltage at Last House over 24 Hours');
        title(S.axBar ,'Worst Case Comparison');
        title(S.axProf,'Voltage Profile along Feeder at Worst Hour');
    end

% ------------------------------ TAB 4 -----------------------------------
    function buildResultsTab(tab)

        uilabel(tab,'Position',[25 600 900 35], ...
            'Text','Numerical Results and Engineering Verdict', ...
            'FontSize',20,'FontWeight','bold','FontColor',[0.05 0.22 0.45]);

        S.resTable = uitable(tab,'Position',[25 330 1050 255], ...
            'ColumnName',{'Quantity','Uncoordinated','Coordinated','Improvement'}, ...
            'ColumnWidth',{380 220 220 200},'FontSize',13);

        S.verdict = uitextarea(tab,'Position',[25 60 1050 250], ...
            'Editable','off','FontName','Consolas','FontSize',12.5, ...
            'BackgroundColor',[1 1 1], ...
            'Value',{'Run the simulation on Tab 3 to generate results.'});

        uibutton(tab,'Position',[25 15 250 35],'Text','Export Results to CSV', ...
            'FontSize',13,'BackgroundColor',[0.20 0.45 0.75],'FontColor','w', ...
            'ButtonPushedFcn',@(~,~) onExport());
    end

% =========================================================================
%                          SIMULATION ENGINE
% =========================================================================
    function p = getParams()
        p.numHouses    = round(S.inp(1).Value);
        p.baseLoad     = S.inp(2).Value;
        p.evPower      = S.inp(3).Value;
        p.chargeHours  = round(S.inp(4).Value);
        p.kvaRating    = S.inp(5).Value;
        p.Vnom         = S.inp(6).Value;
        p.Rseg         = S.inp(7).Value;
        p.tolPct       = S.inp(8).Value;
        p.peakStart    = round(S.peakStart.Value);
        p.offpeakStart = round(S.offStart.Value);
        p.stagger      = round(S.stagger.Value);
        p.evFlags      = S.evTable.Data.Owns_EV;
    end

    function R = runSim(p, mode)

        % typical residential daily load shape (24 multipliers, 00:00-23:00)
        shape = [0.35 0.30 0.28 0.27 0.28 0.35 0.50 0.65 0.60 0.55 0.52 0.55 ...
                 0.60 0.58 0.55 0.58 0.70 0.85 1.00 1.00 0.95 0.80 0.60 0.45];

        N     = p.numHouses;
        baseP = p.baseLoad * shape;            % kW, one house, 1x24
        evP   = zeros(N,24);

        evIdx = find(p.evFlags);
        nEV   = numel(evIdx);

        for k = 1:nEV
            if strcmpi(mode,'Uncoordinated')
                startH = p.peakStart;                       % all together
            else
                startH = mod(p.offpeakStart + (k-1)*p.stagger, 24);
            end
            for d = 0:p.chargeHours-1
                h = mod(startH + d, 24) + 1;                % MATLAB index
                evP(evIdx(k),h) = p.evPower;
            end
        end

        houseP = repmat(baseP, N, 1) + evP;                 % kW  N x 24
        total  = sum(houseP,1);                             % kW  1 x 24
        load   = total / p.kvaRating * 100;                 % percent

        % radial voltage drop, cumulative from transformer outward
        Vh = zeros(N,24);
        for h = 1:24
            drop = 0;
            for n = 1:N
                Pdown = sum(houseP(n:N,h)) * 1000;          % W downstream
                I     = Pdown / p.Vnom;                     % A in segment n
                drop  = drop + I * p.Rseg;                  % V
                Vh(n,h) = p.Vnom - drop;
            end
        end

        R.total   = total;
        R.loading = load;
        R.Vh      = Vh;
        R.Vend    = Vh(N,:);
        R.houseP  = houseP;
        R.nEV     = nEV;
    end

    function onRun()
        p = getParams();

        if p.numHouses < 2
            uialert(S.fig,'Need at least two houses on the feeder.','Input error');
            return
        end

        res.Uncoordinated = runSim(p,'Uncoordinated');
        res.Coordinated   = runSim(p,'Coordinated');

        plotAll(p);
        fillResults(p);

        S.status.Text = sprintf(['Status : simulation complete.  %d houses, ' ...
            '%d EVs, %.0f kVA transformer.'], p.numHouses, ...
            res.Uncoordinated.nEV, p.kvaRating);
        S.tg.SelectedTab = S.tg.Children(3);
    end

% =========================================================================
%                              PLOTTING
% =========================================================================
    function plotAll(p)
        h = 0:23;
        A = res.Uncoordinated;
        B = res.Coordinated;

        % ---- transformer loading ----
        cla(S.axLoad);
        plot(S.axLoad,h,A.loading,'-o','LineWidth',2,'Color',[0.85 0.15 0.15]);
        hold(S.axLoad,'on');
        plot(S.axLoad,h,B.loading,'-s','LineWidth',2,'Color',[0.10 0.55 0.25]);
        yline(S.axLoad,100,'--k','Rated 100%','LineWidth',1.5);
        hold(S.axLoad,'off');
        xlabel(S.axLoad,'Hour of day'); ylabel(S.axLoad,'Loading (%)');
        title(S.axLoad,'Transformer Loading over 24 Hours');
        legend(S.axLoad,{'Uncoordinated','Coordinated'},'Location','northwest');
        grid(S.axLoad,'on'); xlim(S.axLoad,[0 23]);

        % ---- voltage at last house ----
        Vmin = p.Vnom * (1 - p.tolPct/100);
        cla(S.axVolt);
        plot(S.axVolt,h,A.Vend,'-o','LineWidth',2,'Color',[0.85 0.15 0.15]);
        hold(S.axVolt,'on');
        plot(S.axVolt,h,B.Vend,'-s','LineWidth',2,'Color',[0.10 0.55 0.25]);
        yline(S.axVolt,Vmin,'--k',sprintf('Lower limit %.1f V',Vmin),'LineWidth',1.5);
        hold(S.axVolt,'off');
        xlabel(S.axVolt,'Hour of day'); ylabel(S.axVolt,'Voltage (V)');
        title(S.axVolt,sprintf('Voltage at House %d (end of feeder)',p.numHouses));
        legend(S.axVolt,{'Uncoordinated','Coordinated'},'Location','southwest');
        grid(S.axVolt,'on'); xlim(S.axVolt,[0 23]);

        % ---- worst case bar comparison ----
        cla(S.axBar);
        vals = [max(A.loading) max(B.loading); ...
                p.Vnom-min(A.Vend) p.Vnom-min(B.Vend)];
        b = bar(S.axBar,vals);
        b(1).FaceColor = [0.85 0.15 0.15];
        b(2).FaceColor = [0.10 0.55 0.25];
        S.axBar.XTickLabel = {'Peak loading (%)','Max voltage drop (V)'};
        legend(S.axBar,{'Uncoordinated','Coordinated'},'Location','northeast');
        title(S.axBar,'Worst Case Comparison'); grid(S.axBar,'on');

        % ---- voltage profile along feeder at worst hour ----
        [~,hw] = min(A.Vend);
        cla(S.axProf);
        plot(S.axProf,1:p.numHouses,A.Vh(:,hw),'-o','LineWidth',2, ...
            'Color',[0.85 0.15 0.15]);
        hold(S.axProf,'on');
        plot(S.axProf,1:p.numHouses,B.Vh(:,hw),'-s','LineWidth',2, ...
            'Color',[0.10 0.55 0.25]);
        yline(S.axProf,Vmin,'--k','Limit','LineWidth',1.5);
        hold(S.axProf,'off');
        xlabel(S.axProf,'House number along feeder');
        ylabel(S.axProf,'Voltage (V)');
        title(S.axProf,sprintf('Voltage Profile at Hour %d (worst hour)',hw-1));
        legend(S.axProf,{'Uncoordinated','Coordinated'},'Location','southwest');
        grid(S.axProf,'on'); xlim(S.axProf,[1 p.numHouses]);
    end

% =========================================================================
%                              ANIMATION
% =========================================================================
    function onAnimate()
        if isempty(res.Uncoordinated)
            uialert(S.fig,'Run the simulation first.','No data');
            return
        end
        p = getParams();
        A = res.Uncoordinated;  B = res.Coordinated;
        Vmin = p.Vnom*(1-p.tolPct/100);
        h = 0:23;

        for t = 1:24
            % loading
            cla(S.axLoad);
            plot(S.axLoad,h(1:t),A.loading(1:t),'-o','LineWidth',2, ...
                'Color',[0.85 0.15 0.15]);
            hold(S.axLoad,'on');
            plot(S.axLoad,h(1:t),B.loading(1:t),'-s','LineWidth',2, ...
                'Color',[0.10 0.55 0.25]);
            yline(S.axLoad,100,'--k','Rated 100%','LineWidth',1.5);
            hold(S.axLoad,'off');
            xlim(S.axLoad,[0 23]);
            ylim(S.axLoad,[0 max(120,max(A.loading)*1.1)]);
            xlabel(S.axLoad,'Hour of day'); ylabel(S.axLoad,'Loading (%)');
            title(S.axLoad,sprintf('Transformer Loading   |   time = %02d:00',t-1));
            grid(S.axLoad,'on');

            % voltage
            cla(S.axVolt);
            plot(S.axVolt,h(1:t),A.Vend(1:t),'-o','LineWidth',2, ...
                'Color',[0.85 0.15 0.15]);
            hold(S.axVolt,'on');
            plot(S.axVolt,h(1:t),B.Vend(1:t),'-s','LineWidth',2, ...
                'Color',[0.10 0.55 0.25]);
            yline(S.axVolt,Vmin,'--k','Lower limit','LineWidth',1.5);
            hold(S.axVolt,'off');
            xlim(S.axVolt,[0 23]);
            ylim(S.axVolt,[min(A.Vend)-5 p.Vnom+3]);
            xlabel(S.axVolt,'Hour of day'); ylabel(S.axVolt,'Voltage (V)');
            title(S.axVolt,sprintf('Voltage at Last House   |   time = %02d:00',t-1));
            grid(S.axVolt,'on');

            % live voltage profile
            cla(S.axProf);
            plot(S.axProf,1:p.numHouses,A.Vh(:,t),'-o','LineWidth',2, ...
                'Color',[0.85 0.15 0.15]);
            hold(S.axProf,'on');
            plot(S.axProf,1:p.numHouses,B.Vh(:,t),'-s','LineWidth',2, ...
                'Color',[0.10 0.55 0.25]);
            yline(S.axProf,Vmin,'--k','Limit','LineWidth',1.5);
            hold(S.axProf,'off');
            xlim(S.axProf,[1 p.numHouses]);
            ylim(S.axProf,[min(A.Vh(:))-3 p.Vnom+2]);
            xlabel(S.axProf,'House number along feeder');
            ylabel(S.axProf,'Voltage (V)');
            title(S.axProf,sprintf('Voltage Profile   |   time = %02d:00',t-1));
            grid(S.axProf,'on');

            S.status.Text = sprintf(['Status : animating ... %02d:00   ' ...
                'uncoordinated loading %.1f%%   coordinated loading %.1f%%'], ...
                t-1, A.loading(t), B.loading(t));
            drawnow;
            pause(0.25);
        end

        plotAll(p);
        S.status.Text = 'Status : animation finished.';
    end

% =========================================================================
%                        SINGLE LINE DIAGRAM
% =========================================================================
    function drawDiagram()
        if ~isfield(S,'axDiag') || ~isvalid(S.axDiag), return, end
        ax = S.axDiag;
        cla(ax);
        hold(ax,'on');

        N = round(S.inp(1).Value);
        flags = S.evTable.Data.Owns_EV;
        if numel(flags) < N, flags(end+1:N) = false; end

        % transformer symbol
        rectangle(ax,'Position',[0.2 0.75 0.9 0.5],'Curvature',0.3, ...
            'FaceColor',[0.20 0.45 0.75],'EdgeColor','k','LineWidth',1.5);
        text(ax,0.65,1.0,'TX','HorizontalAlignment','center', ...
            'Color','w','FontWeight','bold','FontSize',12);
        text(ax,0.65,0.55,sprintf('%.0f kVA',S.inp(5).Value), ...
            'HorizontalAlignment','center','FontSize',10);

        xs = linspace(2.2, 11, N);

        % feeder line
        plot(ax,[1.1 xs(end)],[1 1],'k','LineWidth',3);

        for n = 1:N
            plot(ax,[xs(n) xs(n)],[1 0.55],'k','LineWidth',1.5);
            if flags(n)
                c = [0.85 0.15 0.15];  lab = sprintf('H%d + EV',n);
            else
                c = [0.45 0.45 0.45];  lab = sprintf('H%d',n);
            end
            plot(ax,xs(n),0.45,'s','MarkerSize',18,'MarkerFaceColor',c, ...
                'MarkerEdgeColor','k','LineWidth',1.2);
            text(ax,xs(n),0.12,lab,'HorizontalAlignment','center', ...
                'FontSize',10,'FontWeight','bold','Color',c);
            text(ax,(xs(n)+ (n==1)*1.1 + (n>1)*xs(max(n-1,1)))/2, 1.18, ...
                sprintf('R=%.3f',S.inp(7).Value), ...
                'HorizontalAlignment','center','FontSize',8, ...
                'Color',[0.3 0.3 0.3]);
        end

        text(ax,0.65,1.55,sprintf('%.0f V bus',S.inp(6).Value), ...
            'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');

        hold(ax,'off');
        xlim(ax,[0 12]); ylim(ax,[0 1.8]);
        ax.XTick = []; ax.YTick = [];
        title(ax,['Single Line Diagram   (red = house with EV charger, ' ...
                  'grey = house without)']);
        ax.Box = 'on';
    end

% =========================================================================
%                         RESULTS AND VERDICT
% =========================================================================
    function fillResults(p)
        A = res.Uncoordinated;  B = res.Coordinated;
        Vmin = p.Vnom*(1-p.tolPct/100);

        pkA = max(A.loading);      pkB = max(B.loading);
        vA  = min(A.Vend);         vB  = min(B.Vend);
        dA  = (p.Vnom-vA)/p.Vnom*100;
        dB  = (p.Vnom-vB)/p.Vnom*100;
        eA  = sum(A.total);        eB = sum(B.total);

        D = { ...
        'Number of houses on feeder', p.numHouses, p.numHouses, '-' ; ...
        'Number of EVs connected',    A.nEV,       B.nEV,       '-' ; ...
        'Peak transformer loading (%)', sprintf('%.1f',pkA), ...
                                        sprintf('%.1f',pkB), ...
                                        sprintf('%.1f %% lower',pkA-pkB) ; ...
        'Transformer overloaded?',  ynStr(pkA>100), ynStr(pkB>100), '-' ; ...
        'Minimum voltage at last house (V)', sprintf('%.1f',vA), ...
                                        sprintf('%.1f',vB), ...
                                        sprintf('%.1f V higher',vB-vA) ; ...
        'Maximum voltage drop (%)', sprintf('%.2f',dA), sprintf('%.2f',dB), ...
                                        sprintf('%.2f %% lower',dA-dB) ; ...
        sprintf('Voltage within %.0f%% limit?',p.tolPct), ...
                                    ynStr(vA>=Vmin), ynStr(vB>=Vmin), '-' ; ...
        'Total daily energy served (kWh)', sprintf('%.1f',eA), ...
                                    sprintf('%.1f',eB), 'identical' ; ...
        };
        S.resTable.Data = D;

        v = {};
        v{end+1} = 'ENGINEERING INTERPRETATION';
        v{end+1} = '';
        v{end+1} = sprintf(['With %d electric vehicles on a %d house feeder fed ' ...
            'by a %.0f kVA transformer:'], A.nEV, p.numHouses, p.kvaRating);
        v{end+1} = '';
        v{end+1} = sprintf(['  Uncoordinated charging pushes the transformer to ' ...
            '%.1f %% of its rating and'], pkA);
        v{end+1} = sprintf(['  drags the far end of the feeder down to %.1f V, ' ...
            'a drop of %.2f %%.'], vA, dA);
        v{end+1} = sprintf(['  Coordinated charging holds the transformer at ' ...
            '%.1f %% and keeps the far end'], pkB);
        v{end+1} = sprintf('  at %.1f V, a drop of only %.2f %%.', vB, dB);
        v{end+1} = '';

        if pkA > 100 && pkB <= 100
            v{end+1} = ['  The transformer is overloaded under uncoordinated ' ...
                        'charging but stays within'];
            v{end+1} = '  its rating once the same vehicles are staggered overnight.';
        elseif pkA > 100 && pkB > 100
            v{end+1} = ['  Both strategies overload the transformer. The feeder ' ...
                        'genuinely needs'];
            v{end+1} = '  reinforcement or a larger transformer at this EV penetration.';
        else
            v{end+1} = ['  The transformer stays within rating in both cases at ' ...
                        'this EV penetration.'];
        end
        v{end+1} = '';

        if vA < Vmin && vB >= Vmin
            v{end+1} = sprintf(['  Voltage violates the %.0f %% statutory limit ' ...
                'under uncoordinated charging'], p.tolPct);
            v{end+1} = '  and is brought back into compliance by coordination alone.';
        elseif vA < Vmin && vB < Vmin
            v{end+1} = sprintf(['  Voltage is outside the %.0f %% limit in both ' ...
                'cases. Conductor upgrade or'], p.tolPct);
            v{end+1} = '  a voltage regulator would be required.';
        else
            v{end+1} = sprintf(['  Voltage remains inside the %.0f %% limit in ' ...
                'both cases.'], p.tolPct);
        end

        v{end+1} = '';
        v{end+1} = 'KEY CONCLUSION';
        v{end+1} = ['  Both strategies deliver exactly the same amount of energy ' ...
                    'to the same'];
        v{end+1} = ['  vehicles. Only the timing differs. This shows that smart ' ...
                    'charging is a'];
        v{end+1} = ['  control problem rather than an infrastructure problem, and ' ...
                    'that demand'];
        v{end+1} = ['  side management can defer expensive network reinforcement.'];
        v{end+1} = '';
        v{end+1} = 'LIMITATIONS AND FUTURE WORK';
        v{end+1} = ['  The model uses a resistive radial approximation and unity ' ...
                    'power factor.'];
        v{end+1} = ['  A full AC load flow, reactive power, unbalanced phases and ' ...
                    'stochastic'];
        v{end+1} = ['  arrival times would refine the result. An optimisation ' ...
                    'routine could'];
        v{end+1} = ['  replace the fixed stagger with a cost or loss minimising ' ...
                    'schedule.'];

        S.verdict.Value = v;
    end

    function s = ynStr(tf)
        if tf, s = 'YES'; else, s = 'NO'; end
    end

    function onExport()
        if isempty(res.Uncoordinated)
            uialert(S.fig,'Run the simulation first.','No data');
            return
        end
        try
            h = (0:23)';
            T = table(h, res.Uncoordinated.total', res.Uncoordinated.loading', ...
                res.Uncoordinated.Vend', res.Coordinated.total', ...
                res.Coordinated.loading', res.Coordinated.Vend', ...
                'VariableNames',{'Hour','Uncoord_kW','Uncoord_Loading_pct', ...
                'Uncoord_Vend','Coord_kW','Coord_Loading_pct','Coord_Vend'});
            writetable(T,'EV_simulation_results.csv');
            uialert(S.fig,['Saved as EV_simulation_results.csv in the current ' ...
                'MATLAB folder.'],'Export complete','Icon','success');
        catch ME
            uialert(S.fig,ME.message,'Export failed');
        end
    end

end
