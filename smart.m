clc; clear; close all;

botToken = '7498768352:AAHitx80pBK36u3RkWoXQXBMnKCZRinCmes'; 
chatID = '1781467825';

fs = 1;  % Sampling frequency (1 Hz)
simTime = 30;  % Simulation duration (seconds)

temp_threshold = 50;  % Maximum temperature (°C)
current_threshold = 15;  % Maximum current (A)
voltage_min = 190;  % Minimum voltage (V)
voltage_max = 250;  % Maximum voltage (V)

rng shuffle; % يجبر MATLAB على استخدام بذرة عشوائية مختلفة في كل تشغيل

% Initialize data matrix
sim_data = zeros(simTime, 6);
sim_data(:,1) = (0:simTime-1)';  % Time vector
sim_data(:,2) = 40 + 15 * randn(simTime, 1);  % Temperature values
sim_data(:,3) = 10 + 5 * randn(simTime, 1);   % Current values
sim_data(:,4) = 220 + 20 * randn(simTime, 1); % Voltage values

% Ensure no NaN or Inf values
sim_data(isnan(sim_data)) = 0;
sim_data(isinf(sim_data)) = 0;

%----------------------------------------------------%

% Create voltage matrix for Simulink
voltage_data = [sim_data(:,1), sim_data(:,4)]; % Time + Voltage
assignin('base', 'voltage_data', voltage_data);

%----------------------------------------------------%

% Create Time matrix for Simulink
time_data = [sim_data(:,1), sim_data(:,1)]; % الوقت في كلا العمودين (زمن + زمن)
assignin('base', 'time_data', time_data);

%----------------------------------------------------%

%Current and Temprture

temperature_data = [sim_data(:,1), sim_data(:,2)]; % Time + Temperature
current_data = [sim_data(:,1), sim_data(:,3)]; % Time + Current

assignin('base', 'temperature_data', temperature_data);
assignin('base', 'current_data', current_data);

%----------------------------------------------------%

% Initialize relay and buzzer
sim_data(:,5) = 1;  % Relay (ON by default)
sim_data(:,6) = 0;  % Buzzer (OFF by default)

%----------------------------------------------------%

disp('🚀 Simulation started...');

for t = 1:simTime
    % Ensure values are within a valid range
    sim_data(t,2:4) = max(0, sim_data(t,2:4));
    
    % Fault detection logic
    voltage_value = sim_data(t,4); % Use a single voltage value
    fault_detected = sim_data(t,2) > temp_threshold || sim_data(t,3) > current_threshold || ...
                     voltage_value < voltage_min || voltage_value > voltage_max;
    sim_data(t,5) = ~fault_detected;  % Turn off relay if fault detected
    sim_data(t,6) = fault_detected;  % Activate buzzer if fault detected

    % Send Telegram notification
    if fault_detected
        message = sprintf('🚨 System fault detected!\n🌡 Temperature: %.2f°C\n⚡ Current: %.2fA\n🔋 Voltage: %.2fV\n🔴 Power disconnected.', ...
            sim_data(t,2), sim_data(t,3), voltage_value);
        telegramURL = sprintf('https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s', ...
            botToken, chatID, urlencode(message));
        
        try
            webread(telegramURL);
            disp('📨 Notification sent to Telegram!');
        catch ME
            disp('⚠ Failed to send notification!');
            disp(ME.message);
        end
    end
    
    fprintf('🕒 %2d | 🔥 %.2f°C | ⚡ %.2fA | 🔋 %.2fV | Relay: %d | Buzzer: %d\n', ...
        t, sim_data(t,2), sim_data(t,3), voltage_value, sim_data(t,5), sim_data(t,6));
    
    pause(1/fs);
end

% Create voltage matrix for Simulink
voltage_data = [sim_data(:,1), sim_data(:,4)]; % Time + Voltage
assignin('base', 'voltage_data', voltage_data);

% Save Data to MATLAB Workspace for Simulink
assignin('base', 'sim_data', sim_data);

disp('✅ sim_data and voltage_data successfully assigned to the base workspace.');

figure;
plot(sim_data(:,1), sim_data(:,2), '-r', 'LineWidth', 1.5); hold on;
plot(sim_data(:,1), sim_data(:,3), '-g', 'LineWidth', 1.5);
plot(sim_data(:,1), sim_data(:,4), '-b', 'LineWidth', 1.5);
plot(sim_data(:,1), sim_data(:,5) * max(sim_data(:,2:4), [], 'all'), '--m', 'LineWidth', 1.5);
plot(sim_data(:,1), sim_data(:,6) * max(sim_data(:,2:4), [], 'all'), '--k', 'LineWidth', 1.5);
hold off;

xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Values', 'FontSize', 12, 'FontWeight', 'bold');
legend('Temperature (°C)', 'Current (A)', 'Voltage (V)', 'Relay (On/Off)', 'Buzzer (On/Off)', 'Location', 'Best');
title('Simulated Sensor Data', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

disp('✅ Simulation ended!');