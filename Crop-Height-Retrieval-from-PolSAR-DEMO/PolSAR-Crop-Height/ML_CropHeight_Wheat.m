%%%****************************************************************************************************
%%% File: ML_CropHeight_Wheat.m
%%% Written by Shuaifeng Hu
%%% 2022-09-06
%%% Function: use ML to estimate Height
%%%****************************************************************************************************
clear; clc; close all;
tic;

%%%****************************************************************************************************
%% SET
Sheet = 'Wheat';
% Number of experiments
Num_Exp = 10;
% Methods
METHODS = {'RF'};
% Sample Rate
rate = 0.80;
% Data Path
Data_path = strcat('DATA_Wheat.xlsx');

%%%****************************************************************************************************
%% Set Path

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
% X: feature  Y: Height
[Num_Point,Num] = size(Sample_data);
Sample_X = Sample_data(:,1:(Num-1));
Sample_Y = Sample_data(:,Num);
Num_Feature = Num-1;
clear Data_path

%% Train
Num_Models = numel(METHODS);

RMSE_min = ones(Num_Models,1);
RMSE_min = RMSE_min.*1000;

bar = waitbar(0,[Sheet ' Data Processing ...']);
for num_Exp =1:Num_Exp
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
    
    [ntrain,~] = size(Ytrain);
    [ntest,~] = size(Ytest);
    
    clear i Xtest_cate Xtrain_cate Ytest_cate Ytrain_cate Z_cate r
    
    %% Remove the mean of Y for training only
    Y_ave = mean(Ytrain);
    Ytrain = Ytrain - repmat(Y_ave,ntrain,1);
    
    
    %% TRAIN ALL MODELS
    
    for m=1:Num_Models
        fprintf(['***** Training ***** //---Methods: ' METHODS{m} '---//Num_Exp:' num2str(num_Exp) '//******\n']);
        eval(['Model = train' METHODS{m} '(Xtrain,Ytrain);']); % Train model
        eval(['Yp = test' METHODS{m} '(Model,Xtest);']);  %Test model
        Yp = Yp + repmat(Y_ave,ntest,1);
        RESULTS(m) = assessment(Ytest,Yp,'regress');
        
        % ScatPlot
        if strcmp(Sheet,'Wheat')
            ScatPlot_Wheat(METHODS{m},Ytest,Yp,RESULTS(m),num_Exp);
        end

        print(figure(num_Exp),[Sheet '_' METHODS{m} '_' num2str(num_Exp) '.bmp'],'-dbmp');
        close all;
        
        % choose Min RMSE to write xlse
        if RESULTS(m).RMSE < RMSE_min(m)
            RMSE_min(m) = RESULTS(m).RMSE;
            Yp_write = Yp;
        end
        
        % write result to excel
        % RESULTS
        xlswrite(['Result_',Sheet,'.xlsx'],...
            ["Num","RMSE","R"],METHODS{m},'A1');
        xlswrite(['Result_',Sheet,'.xlsx'],...
            [num_Exp],METHODS{m},strcat('A',num2str(num_Exp+1)));
        xlswrite(['Result_',Sheet,'.xlsx'],...
            [RESULTS(m).RMSE],METHODS{m},strcat('B',num2str(num_Exp+1)));
        xlswrite(['Result_',Sheet,'.xlsx'],...
            [RESULTS(m).R],METHODS{m},strcat('C',num2str(num_Exp+1)));
        
        waitbar(num_Exp/Num_Exp,bar,[Sheet ' by ' METHODS{m} ' Method Processing ...']);
    end
    
end
close(bar);
toc;
