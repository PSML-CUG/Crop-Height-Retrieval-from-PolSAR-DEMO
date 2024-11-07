%%%****************************************************************************************************
%%% File: Feature_Select_R.m
%%% Written by Shuaifeng Hu
%%% 2022-09-08
%%% Function: Forward selection procedure to find the optimal feature combination
%%%****************************************************************************************************
clear; clc; close all;
tic;

%%%****************************************************************************************************
%% SET
Sheet = 'Wheat';
METHODS = {'RF'};
% Sample Rate
rate = 0.80;
% Data Path
Data_path = strcat('DATA_Wheat.xlsx');

%%%****************************************************************************************************
%% Set  path
% add assist path
addpath('./AUXF')       % Auxiliary functions for visualization, results analysis, plots, etc.

% add methods path
addpath('./standard')   % Train-Test functions for all methods
addpath('./SVM')        % libsvm code and kernel matrix
addpath('./MRVM')       % Relevance vector machine (RVM)
addpath('./VHGPR')      % Variational Heteroscedastic Gaussian Process regression [Lázaro-Gredilla, 2011]
addpath('./ARES')       % ARESLab -- Adaptive Regression Splines toolbox for Matlab/Octave, ver. 1.5.1, by Gints Jekabsons
addpath('./LWP')        % Locally-Weighted Polynomials, Version 1.3, by Gints Jekabsons
addpath('./WGP')        % Warped GPs
addpath('./SSGP')       % Sparse Spectrum Gaussian Process (SSGP)  [Lázaro-Gredilla, 2008]
addpath('./TGP')        % Twin Gaussian Process (TGP) [Liefeng Bo and Cristian Sminchisescu]  http://www.maths.lth.se/matematiklth/personal/sminchis/code/TGP.html
addpath('./XGB')        % Extreme Gradient Boosting Trees
addpath(genpath('./CCFS/src')); % Canonical Correlation Forests

%% Read Sample Data
% selected
if strcmp(Sheet,'Wheat')
    table_data = 'b3:ah590';
end

% read
Sample_data = xlsread(Data_path,Sheet,table_data);

% X: feature   Y: Height
[Num_Point,Num] = size(Sample_data);
Sample_X = Sample_data(:,1:(Num-1));
Sample_Y = Sample_data(:,Num);
Num_Feature = Num-1;
clear Data_path table_data

%% Split Training-Testing Data

 % 40:100 100:160 160:220 220:280 280:340
    Z = sortrows(Sample_data,Num_Feature+1);
    Z_0_20 = Z((Z(:,Num)<=20 & Z(:,Num)>0),:);
    Z_20_40 = Z((Z(:,Num)<=40 & Z(:,Num)>20),:);
    Z_40_60 = Z((Z(:,Num)<=60 & Z(:,Num)>40),:);
    Z_60_80 = Z((Z(:,Num)<=80 & Z(:,Num)>60),:);
    Z_80_100 = Z((Z(:,Num)<=100 & Z(:,Num)>80),:);
    Z_100_120 = Z((Z(:,Num)<=120 & Z(:,Num)>100),:);
    labels = {Z_0_20,Z_20_40,Z_40_60,Z_60_80,Z_80_100,Z_100_120};

Xtrain = [];
Ytrain = [];
Xtest = [];
Ytest = [];

for i = 1:length(labels)
    Z_cate = cell2mat(labels(i));
    [Z_cate_num,~] = size(Z_cate);
    r = randperm(Z_cate_num);                 % random index
    ntrain = round(rate*Z_cate_num);          % training samples
    Xtrain_cate = Z_cate(r(1:ntrain),1:Num_Feature);       % training set
    Ytrain_cate = Z_cate(r(1:ntrain),Num);       % observed training variable
    Xtest_cate  = Z_cate(r(ntrain+1:end),1:Num_Feature);   % test set
    Ytest_cate  = Z_cate(r(ntrain+1:end),Num);   % observed test variable
    Xtrain = [Xtrain;Xtrain_cate];
    Ytrain = [Ytrain;Ytrain_cate];
    Xtest = [Xtest;Xtest_cate];
    Ytest = [Ytest;Ytest_cate];
end
clear i

[ntrain,~] = size(Ytrain);
[ntest,~] = size(Ytest);

clear i Xtest_cate Xtrain_cate Ytest_cate Ytrain_cate Z_cate r

%% Remove the mean of Y for training only
Y_ave = mean(Ytrain);
Ytrain = Ytrain - repmat(Y_ave,ntrain,1);

%% Featur Select
Num_Models = numel(METHODS);

Feature_Name = ["A";"ALPHA";"C11";"C22";"C33";"DELTA_arg";"DELTA_mod";"GRVI";"H";"MO_HHHV";...
    "MO_HHpVV_HHrVV";"MO_HHVV";"MO_HVVV";"PC_F";"PD";"PD_F";"PH_HHHV";"PH_HHpVV_HHrVV";"PH_HHVV";...
    "PH_HVVV";"PS";"PS_F";"PV";"PV_F";"RA_HHVV";"RA_HVHH";"RA_HVVV";"RVI";"SPAN";"T11";"T22";"TAU"];
Feature_Order=[];

%% Select Feature by R
for m = 1:Num_Models
    RMSE_Box = zeros(Num_Feature,Num_Feature);
    R_Box = zeros(Num_Feature,Num_Feature);
    Xtrain_maxR = [];
    Xtest_maxR = [];
    R_max = 0.01;
    F_index = zeros(1,Num_Feature);
    
    % RMSE
    % Process Display
    disp(['\\ ***Feature Selecting ...  \\ *** Methods:  ' METHODS{m}]);
    progressbar('Main Progress','Feature Selecting by RMSE');
    for i =1:Num_Feature
        r_max = 0.01;
        for j = 1:(Num_Feature-i+1)
            XTRAIN = [Xtrain_maxR,Xtrain(:,j)];
            XTEST = [Xtest_maxR,Xtest(:,j)];
            eval(['model = train' METHODS{m} '(XTRAIN,Ytrain);']); % Train the model
            eval(['Yp = test' METHODS{m} '(model,XTEST);']);       % Test the model
            Yp = Yp+repmat(Y_ave,ntest,1);
            RESULTS = assessment(Ytest, Yp, 'regress');
            RMSE_Box(j,i) = RESULTS.RMSE;
            R_Box(j,i) = RESULTS.R;
            
            if RESULTS.R > r_max
                XTRAIN_maxR = XTRAIN;
                XTEST_maxR = XTEST;
                F_index(i) = j;
                Results_maxR = RESULTS;
                r_max = RESULTS.R;
                Yp_max = Yp;
            end
            
            if RESULTS.R > R_max
                RESULTS_maxR = RESULTS;
                R_max = RESULTS.R;
                YP_maxR = Yp;
            end
            
            % Bar
            frac2 = j/(Num_Feature-i+1);
            frac1 = ((i-1) + frac2)/Num_Feature;
            progressbar(frac1, frac2);
        end
        % Remove min RMSE
        Feature_Order = [Feature_Order;Feature_Name(F_index(i))];
        Xtrain(:,F_index(i)) = [];
        Xtest(:,F_index(i)) = [];
        Feature_Name(F_index(i)) = [];
        Xtrain_maxR = XTRAIN_maxR;
        Xtest_maxR = XTEST_maxR;
    end
    
    % Opt Feature
    RMSE_Box(RMSE_Box==0) = Inf;
    RMSE_Box = sort(RMSE_Box);
    R_Box(R_Box==0)=-Inf;
    R_Box = sort(R_Box,'descend');
    [~,Num_Opt_R]=find(R_Box==max(max(R_Box)));
    Feature_Opt = Feature_Order(1:Num_Opt_R);
    
    % Plot the max R
    if strcmp(Sheet,'Wheat')
        ScatPlot_Wheat(METHODS{m},Ytest,Yp_max,RESULTS_maxR,1);
    end
    print(figure(1),[ Sheet '_' METHODS{m} '.bmp'],'-dbmp');
    close all;
    
    % disp
    disp('The Optimal Feature is');
    disp(Feature_Opt);
    
    % Write to Save
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        ["ME";"RMSE";"RELRMSE";"MAE";"R";"RP";"R2"],'RESULTS','A1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        struct2cell(RESULTS_maxR),'RESULTS','B1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        ["Measured CropHeight";Ytest],'Scat_Plot','A1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        ["Estimated CropHeight";YP_maxR],'Scat_Plot','B1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        ["Feature_Order";Feature_Order],'Feature_Opt','A1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        ["Feature_Opt";Feature_Opt],'Feature_Opt','B1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        RMSE_Box,'RMSE_Box','A1');
    xlswrite([Sheet,'_',METHODS{m},'.xlsx'],...
        R_Box,'R_Box','A1'); 
    
    [~,num_OptComb_R]=find(R_Box==max(max(R_Box)));
    figure(2);
    x=1:1:Num_Feature;
    y_maxR=R_Box(1,:);
    y_others=R_Box(2:end,:);
    plot(x,y_others,'o','LineWidth',0.5,'MarkerSize',5,'MarkerEdgeColor',[180 180 180]/255);
    plot(x,y_maxR,'o-','color',[202,62,71]/255,'LineWidth',0.5,'MarkerSize',5,'MarkerEdgeColor',[202,62,71]/255,'MarkerFaceColor',[202,62,71]/255);
    hold on;
    axis([0 33 0.6 1]);
    set(gca,'xTick',(0:5:33),'yTick',(0.6:0.1:1));
    set(gca,'fontsize',15,'fontname','Times New Roman');
    xlabel('Number of Features');
    ylabel('R');
    MaxR=max(max(R_Box));
    plot(num_OptComb_R(1),MaxR,'o','LineWidth',0.5,'MarkerSize',5.2,'MarkerEdgeColor',[65,65,65]/255,'MarkerFaceColor',[65,65,65]/255);
    text(num_OptComb_R(1)-1.2,MaxR+0.035,num2str(MaxR,'%.2f'),'FontSize',15,'fontname','Times New Roman');
    grid;
    print(figure(2),[ Sheet '_' METHODS{m} '_Result.bmp'],'-dbmp');
    
    
    
end

toc;