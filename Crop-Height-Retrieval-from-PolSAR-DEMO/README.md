%   Code_Package Name：Crop Height Retrieval from PolSAR-DEMO
%  Version:   simpleRegression 3.1 Matlab toolbox
%  Author:   Shuaifeng Hu (shuaifenghu@cug.edu.cn), China University of Geosciences (Wuhan)
%  Tutor: Qinghua Xie (xieqh@cug.edu.cn), China University of Geosciences (Wuhan)
%  Date: Nov 2024
% Copyright (c) 2024 by Shuaifeng Hu and Qinghua Xie, China University of Geosciences (Wuhan)


This demo shows the RFR method and forward feature selection algorithm for crop height retrieval of wheat .

%%%  NOTE：Need to download SimpleR Toolbox URL: https://github.com/IPL-UV/simpleR

%  Step1
%  After feature extraction using SNAP 8.0, imported into Excel to .xlsx file (DATA_Wheat.xlsx)

%  Step2
%  The main function (ML_CropHeight_Wheat.m) is used to get the machine learning inversion results.
%  This procedure calls the ScatPlot_Wheat drawing function
%  The final run yields an excel and 10 graph of the results (see Result_ML_CropHeight_Wheat)


%  Step3
%  Feature optimization using the main function (Feature_Select_R)
%  End up with an excel (including evaluation metrics + feature screening results) and 2 graphs (see Result_Feature_Select_R)

%  Step4
%  Import the excel obtained from RFR and Feature optimization into the Origin software to beautify the scatterplot results.



%%%   The programs contained in this package are granted free of charge for
   research and education purposes only. Scientific results produced using
   the software provided shall acknowledge the use of this implementation
   provided by us. If you plan to use it for non-scientific purposes,
   don't hesitate to contact us. Because the programs are licensed free of
   charge, there is no warranty for the program, to the extent permitted
   by applicable law. except when otherwise stated in writing the
   copyright holders and/or other parties provide the program "as is"
   without warranty of any kind, either expressed or implied, including,
   but not limited to, the implied warranties of merchantability and
   fitness for a particular purpose. the entire risk as to the quality and
   performance of the program is with you. should the program prove
   defective, you assume the cost of all necessary servicing, repair or
   correction. In no event unless required by applicable law or agreed to
   in writing will any copyright holder, or any other party who may modify
   and/or redistribute the program, be liable to you for damages,
   including any general, special, incidental or consequential damages
   arising out of the use or inability to use the program (including but
   not limited to loss of data or data being rendered inaccurate or losses
   sustained by you or third parties or a failure of the program to
   operate with any other programs), even if such holder or other party
   has been advised of the possibility of such damages.

   NOTE: This is just a demo providing a default initialization. Training
   is not at all optimized. Other initializations, optimization techniques,
   and training strategies may be of course better suited to achieve improved
   results in this or other problems. We just did it in the standard way for
   illustration purposes and dissemination of these models.
