function [S,HDR] = remove5060hz(arg1,arg2,arg3)
%  REMOVE5060HZ removes line interference artifacts 
%	from biomedical signal data. 
%        
%   [s,HDR] = remove5060hz(fn, Mode)
%   [s,HDR] = remove5060hz(fn, CHAN, Mode)
%   [s,HDR] = remove5060hz(s, HDR, Mode)
%       
% INPUT:    
% 	fn	biosignal file
%	CHAN	channel selection [default: 0 (all)]      
%	s	signal data
%	HDR	header structure (contains labels, sampling rate etc)
%	Mode    'PCA', 'PCA 50'	50 Hz PCA/SVD filter 
%		'NOTCH'  	50 Hz FIR Notch filter, order=3
%		'NOTCH+'	50 Hz FIR Notch filter
%		'PCA 60'	60 Hz PCA/SVD filter
%		'NOTCH 60' 	60 Hz FIR Notch filter, order=3
%		'NOTCH 60+' 	60 Hz FIR Notch filter
% OUTPUT:    
%	s	corrected signal data
%	HDR	header structure 
%
%
% see also: REGRESS_EOG
%
% Reference(s):
% 


% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

%	$Id: remove5060hz.m,v 1.1 2006-07-26 21:47:31 schloegl Exp $
%	(C)2006 by Alois Schloegl <a.schloegl@ieee.org>	
%    	This is part of the BIOSIG-toolbox http://biosig.sf.net/


if ischar(arg1),
	CHAN = 0; 
        if (nargin>1) 
                if ischar(arg2)
		      	MODE = arg2;
		      	CHAN = 0; 
		else
			MODE = '50';
			CHAN = arg2;        	 
		end;  	
        end; 	
        [s,HDR] = sload(arg1,CHAN);
        
elseif isnumeric(arg1) & isstruct(arg2)
	s = arg1; 
	HDR = arg2; 
        if (nargin>2)
        	MODE = arg3;
        end;	 
end


NotchFreq = 50; 	% default 50 Hz Notch
if strfind(upper(MODE),'60')
	NotchFreq = 60; 
end;		


warning('REMOVE5060Hz is not validated, yet.');

if strfind(upper(MODE),'PCA') % strfind(upper(MODE),'SVD')

	bw = 1;  % bandwidth of 1 Hz	
	r = exp(-bw/HDR.SampleRate);	% convert bandwidth into magnitude of poles  
	%B = real(r*poly(exp(i*2*pi/HDR.SampleRate*[NotchFreq:2*NotchFreq:HDR.SampleRate-NotchFreq])));
	B = real(poly(r*exp(i*2*pi*NotchFreq/HDR.SampleRate*[1,-1])));
	
	%%%%% identify 50/60 Hz component 
	[u,d,v]  = svd(filtfilt(1,B,s),0); % s = u*d*v';
	[tmp,ix] = max(diag(d));
	
	%%%%% regress 50/60 Hz component
	[R,S] = regress_eog([s,u(:,ix)],1:size(s,2),size(s,2)+1);	% regression on filtered component 
	%[R2,s2] = regress_eog(s,1:size(s,2),v(:,ix));			% regression on raw component

	
elseif strfind(upper(MODE),'ICA')

	%%%%% not implemented %%%%%	
	error('ICA method not implemented');


elseif ~isempty(strfind(upper(MODE),'NOTCH'))
	if ~isempty(strfind(upper(MODE),'+'))
		B = real(poly(exp(i*2*pi/HDR.SampleRate*[NotchFreq,HDR.SampleRate-NotchFreq])));
	else
		B = real(poly(exp(i*2*pi/HDR.SampleRate*[NotchFreq:2*NotchFreq:HDR.SampleRate-NotchFreq/2])));
	end;
	S = filtfilt(B/sum(B),1,s); 

else
	warning('unknown method: no correction applied.');

end;
		



