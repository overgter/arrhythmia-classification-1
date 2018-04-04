function [net] = arrhythmia_network(samples, labels, hiddenLayerSize)

%% Model
net = patternnet(hiddenLayerSize);
net.divideParam.trainRatio = 50/100;
net.divideParam.valRatio = 25/100;
net.divideParam.testRatio = 25/100;

%% Train
targets = ind2vec(labels');
[net, tr] = train(net, samples, targets);

%% Test
out = net(samples);
err = gsubtract(targets, out);
perf = perform(net, targets, out);

%% Performance plots
% Performance plot
figure, plotperform(tr)
% Training plot
figure, plottrainstate(tr)
% Confusion per class
figure, plotconfusion(targets, out)
% Errors histogram
figure, ploterrhist(err);
end