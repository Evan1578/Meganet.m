classdef batchNormLayer < abstractMeganetElement
    % classdef batchNormLayer < abstractMeganetElement
    %
    % tailored implementation of batch normalization layer. Same can be
    % achieved by stacking an affineScalingLayer and a normLayer in a
    % Neural Network. However, this would entail unnecessary temp
    % variables.
    properties
        nData       % describe size of data, at least first two dim must be correct.
        isWeight     % transformation type
        useGPU      % flag for GPU computing 
        precision   % flag for precision 
        eps
    end
    methods
        function this = batchNormLayer(nData,varargin)
            if nargin==0
                help(mfilename)
                return;
            end
            useGPU     = 0;
            precision  = 'double';
            eps = 1e-4;
            for k=1:2:length(varargin)     % overwrites default parameter
                    eval([varargin{k},'=varargin{',int2str(k+1),'};']);
            end
            
            this.useGPU = useGPU;
            this.precision = precision;
            this.nData = nData;
            this.eps = eps;
        end
        function [s2,b2] = split(this,theta)
            s2 = reshape(theta(1:this.nData(2)),1,this.nData(2),1);
            cnt = numel(s2);
            b2 = reshape(theta(cnt+(1:this.nData(2))),1,this.nData(2),1);
        end
        
        function [Ydata,Y,dA] = apply(this,theta,Y,varargin)
           
           Y   = reshape(Y,this.nData(1), this.nData(2),[]); dA = [];
           nex = size(Y,3);
           % normalization
           
           Y  = Y-mean(Y,3);
           
           Y  = Y./sqrt(mean(Y.^2,3)+this.eps);
           
           % scaling
           [s2,b2] = split(this,theta);           
           Y = Y.*s2;
           Y = Y + b2;
           Y = reshape(Y,[],nex);
           Ydata = Y;
        end
        
        
        function n = nTheta(this)
            n = 2*this.nData(2);
        end
        
        function n = nFeatIn(this)
            n = prod(this.nData(1:2));
        end
        
        function n = nFeatOut(this)
            n = prod(this.nData(1:2));
        end
       
        function n = nDataOut(this)
            n = nFeatOut(this);
        end
        
        function theta = initTheta(this)
            [s2,b2] = split(this,ones(this.nTheta,1));
            theta = [s2(:); 0*b2(:);];
            theta = gpuVar(this.useGPU,this.precision,theta);
        end
        
        
        function [dYdata,dY] = Jthetamv(this,dtheta,theta,Y,~)
           Y   = reshape(Y,this.nData(1), this.nData(2),[]);
           nex = size(Y,3);
           [ds2,db2] = split(this,dtheta);
           
           % normalization
           Y  = Y-mean(Y,3);
           Y  = Y./sqrt(mean(Y.^2,3)+this.eps);
           
           % scaling
           dY = Y.*ds2;
           dY = dY + db2;
           
           dY = reshape(dY,[],nex);
           dYdata = dY;
        end
        
        function dtheta = JthetaTmv(this,Z,~,theta,Y,~)
            Y   = reshape(Y,this.nData(1), this.nData(2),[]);
            Z   = reshape(Z,this.nData(1), this.nData(2),[]);
            % normalization
           Y  = Y-mean(Y,3);
           Y  = Y./sqrt(mean(Y.^2,3)+this.eps);
           
            W = Y.*Z;
            dtheta     = vec(sum(sum(W,1),3));
            dtheta = [dtheta; vec(sum(sum(Z,1),3))];
        end
       
        
        function [dYdata,dY] = JYmv(this,dY,theta,Y,~)
            dY   = reshape(dY,this.nData(1), this.nData(2),[]);
            nex = size(dY,3);
            s2 = split(this,theta);
            
            % normalization
            nf  = this.nData(2);
            Y    = reshape(Y,[],nf,nex);
            
            Fy  = Y-mean(Y,3);
            FdY = dY-mean(dY,3);
            den = sqrt(mean(Fy.^2,3)+this.eps);
            
            dY = FdY./den  - (Fy.* (mean(Fy.*FdY,3) ./(den.^3))) ;
            % scaling
            dY = dY.*s2;
            dY = reshape(dY,[],nex);
            dYdata = dY;
        end
        
        function FdY = JYTmv(this,FdY,~,theta,Y,~)
           FdY   = reshape(FdY,this.nData(1), this.nData(2),[]); 
           Y   = reshape(Y,this.nData(1), this.nData(2),[]); 
           nex = size(FdY,3);
           % scaling
           s2 = split(this,theta);
           FdY = FdY.*s2;
           
           % normalization
           Fy  = Y-mean(Y,3);
           FdY = FdY-mean(FdY,3);
           den = sqrt(mean(Fy.^2,3)+this.eps);
           
           tt = mean(Fy.*FdY,3) ./(den.^3);
           FdY = FdY./den;
           clear den;
           FdY = FdY - Fy.*tt;
           FdY = reshape(FdY,[],nex);
        end
        
        
        % ------- functions for handling GPU computing and precision ---- 
        function this = set.useGPU(this,value)
            if (value~=0) && (value~=1)
                error('useGPU must be 0 or 1.')
            else
                this.useGPU  = value;
            end
        end
        function this = set.precision(this,value)
            if not(strcmp(value,'single') || strcmp(value,'double'))
                error('precision must be single or double.')
            else
                this.precision = value;
            end
        end
        function useGPU = get.useGPU(this)
            useGPU = this.useGPU;
        end
        function precision = get.precision(this)
            precision = this.precision;
        end
    end
end


