function ScatPlot_Wheat(Name,Ytest, Ypred,RESULTS,num_Exp)
figure(num_Exp);
x = 0:0.1:350;
y=x;
plot(x,y,'--','color', [80 80 80]/255,'LineWidth', 1);
hold on;
plot (Ytest,Ypred,'o','color',[0 114 189]/255,'LineWidth', 0.5,'MarkerSize', 6,'MarkerFaceColor',[0 114 189]/255);
set(gca,'LineWidth',1,'fontsize',16,'fontname' ,'Times New Roman','FontWeight','bold');
xlabel('Observed Height (cm)');
ylabel('Estimated Height (cm)');
str = {{['ME= ',num2str(RESULTS.ME)],['RMSE= ',num2str(RESULTS.RMSE)]},{['MAE= ',num2str(RESULTS.MAE)],['R= ',num2str(RESULTS.R)]}};
axis([0 100 0 100]);

text([70,70],[22,10],str,'k','FontSize',13,'fontname','Times New Roman','FontWeight','bold');
title (Name,'fontsize',16,'fontname' ,'Times New Roman','FontWeight','bold');
grid;
end