function [thi,wi,idi]=  inter1D(theta,ttheta,ti)
if nargin==0
   runMinimalExample;
   return
end

theta = reshape(theta,[],numel(ttheta));

thi = zeros(size(theta,1),numel(ti),'like',theta);
wi  = zeros(2,numel(ti));
idi = zeros(2,numel(ti));

for k=1:numel(ti)
    % get theta for current time point
    idth   = find(ttheta<=ti(k),1,'last');
    if  isempty(idth)
        thi(:,k) = theta(:,1);
        wi(:,k) = [1;0];
        idi(:,k) = [1;2];
    elseif idth == numel(ttheta)
        thi(:,k) = theta(:,end);
        wi(:,k)  = [0; 1];
        idi(:,k) = [numel(ttheta)-1 numel(ttheta)];
    else
        idi(:,k)    = [idth; idth+1];
        thl    = ttheta(idi(1,k));  thr = ttheta(idi(2,k));
        hth    = thr-thl;
        wi(:,k)     = [thr-ti(k) ti(k)-thl]/hth;
        thi(:,k) = wi(1,k) *theta(:,idth)  + wi(2,k) * theta(:,idth+1);
    end
end

function runMinimalExample
theta  = [ 2 4 2 6; 4 2 1 2];
ttheta = [ 1 2 4 5];
ti     = linspace(0,6,101);
thi    = feval(mfilename,theta,ttheta,ti);

figure(99); clf;
plot(ttheta,theta(1,:)','or',ttheta,theta(2,:),'sb');
hold on;
plot(ti,thi(1,:)','-r',ti,thi(2,:)','-b');

