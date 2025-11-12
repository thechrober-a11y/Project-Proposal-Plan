%% === Load data from workspace ===
T = datadate;  % your loaded table

%% === Data Cleaning & Preparation ===
T.Date = datetime(T.Date, 'InputFormat', 'yyyy-MM-dd');
T.Status = categorical(T.Status);
T.AQIValue = double(T.AQIValue);

T = unique(T);
T = rmmissing(T);
T = T(T.AQIValue >= 0 & T.AQIValue <= 500, :);

fprintf('Cleaned dataset: %d rows, %d columns\n', height(T), width(T));

%% === Add Year Column ===
T.Year = year(T.Date);

%% === 1. Global AQI Histogram with Health Categories & Threshold Lines ===
edges = 0:25:500;  % histogram bin edges

% AQI categories and colors
categoriesAQI = {'Good','Moderate','Unhealthy for Sensitive','Unhealthy','Very Unhealthy','Hazardous'};
catEdges = [0 50 100 150 200 300 500];
colors = [0 0.7 0;       % Green
          1 1 0;         % Yellow
          1 0.65 0;      % Orange
          1 0 0;         % Red
          0.6 0 0.6;     % Purple
          0.55 0 0];     % Maroon

countsCategory = zeros(length(catEdges)-1,1);
figure; hold on;
for i = 1:length(catEdges)-1
    idx = T.AQIValue >= catEdges(i) & T.AQIValue < catEdges(i+1);
    countsCategory(i) = sum(idx);
    bar(mean([catEdges(i) catEdges(i+1)]), countsCategory(i), catEdges(i+1)-catEdges(i), 'FaceColor', colors(i,:), 'EdgeColor','k');
end

% Add vertical threshold lines
for v = 2:length(catEdges)-1
    xline(catEdges(v), '--k','LineWidth',1.2);
end

title('Global AQI Distribution by Health Category','FontWeight','bold','FontSize',14);
xlabel('AQI Value'); ylabel('Frequency'); grid on; xlim([0 500]);
legend(categoriesAQI,'Location','northeastoutside');
hold off;

% Display table for histogram
histTable = table(categoriesAQI', countsCategory, 'VariableNames', {'Category','Count'});
disp('Global AQI Histogram Values:');
disp(histTable);

%% === 2. Annual Mean AQI Line Chart (Top 10 Worst Countries) ===
% Top 10 countries by overall mean AQI
countryMeans = groupsummary(T, "Country", "mean", "AQIValue");
countryMeans = sortrows(countryMeans, "mean_AQIValue", "descend");
topN = 10;
topCountries = countryMeans.Country(1:min(topN, height(countryMeans)));

% Annual stats for top countries
annualStats = groupsummary(T, ["Year","Country"], "mean", "AQIValue");
annualStatsTop = annualStats(ismember(annualStats.Country, topCountries), :);

figure; hold on;
colorsTop = lines(length(topCountries));
for i = 1:length(topCountries)
    idx = annualStatsTop.Country == topCountries(i);
    plot(annualStatsTop.Year(idx), annualStatsTop.mean_AQIValue(idx), '-o', ...
        'LineWidth',1.5,'MarkerSize',5,'Color',colorsTop(i,:), ...
        'DisplayName',string(topCountries(i)));
end

% Highlight worst country each year
years = unique(T.Year);
for y = years'
    yearlyData = annualStatsTop(annualStatsTop.Year==y, :);
    [~, idxMax] = max(yearlyData.mean_AQIValue);
    worstCountry = yearlyData.Country(idxMax);
    worstValue = yearlyData.mean_AQIValue(idxMax);
    plot(y, worstValue, 'r*', 'MarkerSize',10, 'LineWidth',1.5);
    text(y, worstValue+2, string(worstCountry),'FontWeight','bold','FontSize',9,'Color','r','HorizontalAlignment','center');
end

hold off;
title('Annual Mean AQI by Top 10 Worst Countries','FontWeight','bold','FontSize',14);
xlabel('Year'); ylabel('Mean AQI Value');
legend('Location','northeastoutside');
grid on; xlim([2022 2025]);

% Display table for annual stats
disp('Annual Mean AQI for Top 10 Countries:');
disp(annualStatsTop);

%% === 3. Pie Chart: Status Distribution Across Top 10 Countries ===
T_top = T(ismember(T.Country, topCountries), :);
countsStatusTop = countcats(T_top.Status);
colorsStatus = lines(length(countsStatusTop));

figure;
h = pie(countsStatusTop);
title('AQI Status Distribution (Top 10 Countries)','FontWeight','bold','FontSize',14);
legend(categories(T_top.Status),'Location','eastoutside');

patchHandles = findobj(h, 'Type', 'Patch');
for j = 1:length(patchHandles)
    patchHandles(j).FaceColor = colorsStatus(j,:);
end

% Display table for status
statusTable = table(categories(T_top.Status), countsStatusTop, 'VariableNames', {'Status','Count'});
disp('AQI Status Distribution for Top 10 Countries:');
disp(statusTable);

%% === 4. Global Daily Mean AQI with 7-Day Moving Average ===
dailyMean = groupsummary(T, "Date", "mean", "AQIValue");
movAvg7 = movmean(dailyMean.mean_AQIValue,7);

figure;
plot(dailyMean.Date, dailyMean.mean_AQIValue, '-o','LineWidth',1.5,'MarkerSize',4,'Color',[0 0.45 0.74]);
hold on;
plot(dailyMean.Date, movAvg7, '-r','LineWidth',2);
hold off;
title('Global Daily Mean AQI with 7-Day Moving Average','FontWeight','bold','FontSize',14);
xlabel('Date'); ylabel('Mean AQI Value');
legend({'Daily Mean','7-Day Moving Average'},'Location','northwest');
grid on; xlim([min(dailyMean.Date) max(dailyMean.Date)]);

% Display table for daily means
dailyTable = table(dailyMean.Date, dailyMean.mean_AQIValue, movAvg7, ...
    'VariableNames', {'Date','DailyMeanAQI','MovingAvg7'});
disp('Global Daily Mean AQI (with 7-day moving average):');
disp(dailyTable);

%% === 5. Global AQI Status Distribution (Pie Chart) ===
countsGlobal = countcats(T.Status);
colorsGlobal = lines(length(countsGlobal));

figure;
h = pie(countsGlobal);
title('Global AQI Status Distribution','FontWeight','bold','FontSize',14);
legend(categories(T.Status),'Location','eastoutside');

patchHandles = findobj(h, 'Type', 'Patch');
for j = 1:length(patchHandles)
    patchHandles(j).FaceColor = colorsGlobal(j,:);
end

% Display table for global status
statusGlobalTable = table(categories(T.Status), countsGlobal, 'VariableNames', {'Status','Count'});
disp('Global AQI Status Distribution:');
disp(statusGlobalTable);

%% === 6. Optional: Annual Mean AQI Bar Chart for Top 10 Countries ===
annualBar = groupsummary(T_top, ["Year","Country"], "mean", "AQIValue");
figure; hold on;
for i = 1:length(topCountries)
    idx = annualBar.Country == topCountries(i);
    bar(annualBar.Year(idx) + 0.1*i, annualBar.mean_AQIValue(idx), 0.08, 'FaceColor', colorsTop(i,:)); 
end
hold off;
title('Annual Mean AQI by Top 10 Countries (Bar Chart)','FontWeight','bold','FontSize',14);
xlabel('Year'); ylabel('Mean AQI Value');
legend(topCountries,'Location','northeastoutside');
grid on; xlim([2022 2025]);
