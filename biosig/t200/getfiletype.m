function [HDR] = getfiletype(arg1)
% GETFILETYPE get file type 
%
% HDR = getfiletype(Filename);
% HDR = getfiletype(HDR.FileName);
%
% HDR is the Header struct and contains stuff used by SOPEN. 
% HDR.TYPE identifies the type of the file [1,2]. 
%
% see also: SOPEN 
%
% Reference(s): 
%   [1] http://www.dpmi.tu-graz.ac.at/~schloegl/matlab/eeg/
%   [2] http://www.dpmi.tu-graz.ac.at/~schloegl/biosig/TESTED 


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

%	$Revision: 1.10 $
%	$Id: getfiletype.m,v 1.10 2004-10-10 20:25:34 schloegl Exp $
%	(C) 2004 by Alois Schloegl <a.schloegl@ieee.org>	
%    	This is part of the BIOSIG-toolbox http://biosig.sf.net/

if ischar(arg1),
        HDR.FileName = arg1;
elseif isfield(arg1,'name')
        HDR.FileName = arg1.name;
	HDR.FILE = arg1; 
elseif isfield(arg1,'FileName')
        HDR = arg1;
end;

HDR.TYPE = 'unknown';
HDR.FILE.OPEN = 0;
HDR.FILE.FID  = -1;
HDR.ERROR.status  = 0; 
HDR.ERROR.message = ''; 
if ~isfield(HDR.FILE,'stderr'),
        HDR.FILE.stderr = 2;
end;
if ~isfield(HDR.FILE,'stdout'),
        HDR.FILE.stdout = 1;
end;	

if exist(HDR.FileName,'dir') 
        [pfad,file,FileExt] = fileparts(HDR.FileName);
        HDR.FILE.File = file; 
        HDR.FILE.Path = pfad; 
	HDR.FILE.Ext  = FileExt(2:end); 
	if strcmpi(FileExt,'.ds'), % .. & isdir(HDR.FileName)
	        f1 = fullfile(HDR.FileName,[file,'.meg4']);
	        f2 = fullfile(HDR.FileName,[file,'.res4']);
	        if (exist(f1,'file') & exist(f2,'file')), % & (exist(f3)==2)
            		HDR.FileName  = f1; 
			% HDR.TYPE = 'MEG4'; % will be checked below 
	        end;
	else
    		HDR.TYPE = 'DIR'; 
    		return; 
	end;
end;

fid = fopen(HDR.FileName,'rb','ieee-le');
if fid < 0,
	HDR.ERROR.status = -1; 
        HDR.ERROR.message = sprintf('Error GETFILETYPE: file %s not found.\n',HDR.FileName);
        return;
else
        [pfad,file,FileExt] = fileparts(HDR.FileName);
        HDR.FILE.Name = file;
        HDR.FILE.Path = pfad;
        HDR.FILE.Ext  = char(FileExt(2:length(FileExt)));

	fseek(fid,0,'eof');
	HDR.FILE.size = ftell(fid);
	fseek(fid,0,'bof');

        [s,c] = fread(fid,132,'uchar');
	s = s';
        if (c < 132),
                s = [s, repmat(0,1,132-c)];
        end;

        if c,
                %%%% file type check based on magic numbers %%%
                type_mat4=str2double(char(abs(sprintf('%04i',s(1:4)*[1;10;100;1000]))'));
                ss = char(s);
                if all(s(1:2)==[207,0]);
                        HDR.TYPE='BKR';
                elseif strncmp(ss,'Version 3.0',11); 
                        HDR.TYPE='CNT';
                elseif strncmp(ss,'0       ',8); 
                        HDR.TYPE='EDF';
                elseif all(s(1:8)==[255,abs('BIOSEMI')]); 
                        HDR.TYPE='BDF';
                elseif strncmp(ss,'GDF',3); 
                        HDR.TYPE='GDF';
                elseif strncmp(ss,'EBS',3); 
                        HDR.TYPE='EBS';
                elseif strncmp(ss,'CEN',3) & all(s(6:8)==hex2dec(['1A';'04';'84'])') & (all(s(4:5)==hex2dec(['13';'10'])') | all(s(4:5)==hex2dec(['0D';'0A'])')); 
                        HDR.TYPE='FEF';
                        HDR.VERSION   = str2double(ss(9:16))/100;
                        HDR.Encoding  = str2double(ss(17:24));
                        if any(str2double(ss(25:32))),
                                HDR.Endianity = 'ieee-be';
                        else
                                HDR.Endianity = 'ieee-le';
                        end;
                        if any(s(4:5)~=[13,10])
                                fprintf(2,'Warning GETFILETYPE (FEF): incorrect preamble in file %s\n',HDR.FileName);
                        end;
                        
                elseif strncmp(ss,'MEG41CP',7); 
                        HDR.TYPE='CTF';
                elseif strncmp(ss,'MEG41RS',7) | strncmp(ss,'MEG4RES',7); 
                        HDR.TYPE='CTF';
                elseif strncmp(ss,'MEG4',4); 
                        HDR.TYPE='CTF';
                elseif strncmp(ss,'CTF_MRI_FORMAT VER 2.2',22); 
                        HDR.TYPE='CTF';
                elseif strncmp(ss,'PATH OF DATASET:',16); 
                        HDR.TYPE='CTF';
                        
                elseif strcmp(ss(1:8),'@  MFER '); 
                        HDR.TYPE='MFER';
                elseif strcmp(ss(1:6),'@ MFR '); 
                        HDR.TYPE='MFER';
                elseif all(s(17:22)==abs('SCPECG')); 
                        HDR.TYPE='SCP';
                elseif strncmp(ss,'ATES MEDICA SOFT',16);	% ATES MEDICA SOFTWARE, NeuroTravel 
                        HDR.TYPE='ATES';
                elseif strncmp(ss,'POLY_SAM',8);	% Poly5/TMS32 sample file format.
                        HDR.TYPE='TMS32';
                elseif strncmp(ss,'"Snap-Master Data File"',23);	% Snap-Master Data File .
                        HDR.TYPE='SMA';
                elseif all(s([1:2,20])==[1,0,0]) & any(s(19)==[2,4]); 
                        HDR.TYPE='TEAM';	% Nicolet TEAM file format
                elseif strncmp(ss,['# ',HDR.FILE.Name],length(HDR.FILE.Name)+2); 
                        HDR.TYPE='SMNI';
                elseif strncmp(ss,HDR.FILE.Name,length(HDR.FILE.Name)); 
                        HDR.TYPE='MIT';
                elseif strncmp(ss,'DEMG',4);	% www.Delsys.com
                        HDR.TYPE='DEMG';
                        
                elseif strncmp(ss,'NEX1',4); 
                        HDR.TYPE='NEX';
                elseif strcmp(ss([1:4]),'fLaC'); 
                        HDR.TYPE='FLAC';
                elseif strcmp(ss([1:4]),'OggS'); 
                        HDR.TYPE='OGG';
                elseif strcmp(ss([1:4]),'.RMF'); 
                        HDR.TYPE='RMF';
                elseif strncmp(ss,'.snd',4); 
                        HDR.TYPE='SND';
                        HDR.Endianity = 'ieee-be';
                elseif strncmp(ss,'dns.',4); 
                        HDR.TYPE='SND';
                        HDR.Endianity = 'ieee-le';
                elseif strcmp(ss([1:4,9:12]),'RIFFWAVE'); 
                        HDR.TYPE='WAV';
                        HDR.Endianity = 'ieee-le';
                elseif strcmp(ss([1:4,9:11]),'FORMAIF'); 
                        HDR.TYPE='AIF';
                        HDR.Endianity = 'ieee-be';
                elseif strcmp(ss([1:4,9:12]),'RIFFAVI '); 
                        HDR.TYPE='AVI';
                        HDR.Endianity = 'ieee-le';
                elseif all(s([1:4,9:21])==[abs('RIFFRMIDMThd'),0,0,0,6,0]); 
                        HDR.TYPE='RMID';
                        HDR.Endianity = 'ieee-be';
                elseif all(s(1:9)==[abs('MThd'),0,0,0,6,0]) & any(s(10)==[0:2]); 
                        HDR.TYPE='MIDI';
			HDR.Endianity = 'ieee-be';
                elseif ~isempty(findstr(ss(1:16),'8SVXVHDR')); 
                        HDR.TYPE='8SVX';
                elseif strcmp(ss([1:4,9:12]),'RIFFILBM'); 
                        HDR.TYPE='ILBM';
                elseif strcmp(ss([1:4]),'2BIT'); 
                        HDR.TYPE='AVR';
                elseif all(s([1:4])==[26,106,0,0]); 
                        HDR.TYPE='ESPS';
                        HDR.Endianity = 'ieee-le';
                elseif all(s([1:4])==[0,0,106,26]); 
                        HDR.TYPE='ESPS';
                        HDR.Endianity = 'ieee-le';
                elseif strcmp(ss([1:15]),'IMA_ADPCM_Sound'); 
                        HDR.TYPE='IMA ADPCM';
                elseif all(s([1:8])==[abs('NIST_1A'),0]); 
                        HDR.TYPE='NIST';
                elseif all(s([1:7])==[abs('SOUND'),0,13]); 
                        HDR.TYPE='SNDT';
                elseif strcmp(ss([1:18]),'SOUND SAMPLE DATA '); 
                        HDR.TYPE='SMP';
                elseif strcmp(ss([1:19]),'Creative Voice File'); 
                        HDR.TYPE='VOC';
                elseif strcmp(ss([5:8]),'moov'); 	% QuickTime movie 
                        HDR.TYPE='QTFF';
                elseif all(s(1:16)==hex2dec(reshape('3026b2758e66cf11a6d900aa0062ce6c',2,16)')')
                        %'75B22630668e11cfa6d900aa0062ce6c'
                        HDR.TYPE='ASF';
                        
                elseif strncmp(ss,'MPv4',4); 
                        HDR.TYPE='MPv4';
                        HDR.Date = ss(65:87);
                elseif strncmp(ss,'RG64',4); 
                        HDR.TYPE='RG64';
                elseif strncmp(ss,'DTDF',4); 
                        HDR.TYPE='DDF';
                elseif strncmp(ss,'RSRC',4);
                        HDR.TYPE='LABVIEW';
                elseif strncmp(ss,'IAvSFo',6); 
                        HDR.TYPE='SIGIF';
                elseif any(s(4)==(2:7)) & all(s(1:3)==0); % [int32] 2...7
                        HDR.TYPE='EGI';
                        
                elseif all(s(1:4)==hex2dec(reshape('AFFEDADA',2,4)')');        % Walter Graphtek
                        HDR.TYPE='WG1';
                        HDR.Endianity = 'ieee-le';
                elseif all(s(1:4)==hex2dec(reshape('DADAFEAF',2,4)')'); 
                        HDR.TYPE='WG1';
                        HDR.Endianity = 'ieee-be';
                        
                elseif strncmp(ss,'RIFF',4)
                        HDR.TYPE='EEProbe-CNT';     % continuous EEG in EEProbe format, ANT Software (NL) and MPI Leipzig (DE)
                elseif all(s(1:4)==[38 0 16 0])
                        HDR.TYPE='EEProbe-AVR';     % averaged EEG in EEProbe format, ANT Software (NL) and MPI Leipzig (DE)
                        
                elseif strncmp(ss,'ISHNE1.0',8);        % ISHNE Holter standard output file.
                        HDR.TYPE='ISHNE';
                elseif strncmp(ss,'rhdE',4);	% Holter Excel 2 file, not supported yet. 
                        HDR.TYPE='rhdE';          
                        
                elseif strncmp(ss,'RRI',3);	% R-R interval format % Holter Excel 2 file, not supported yet. 
                        HDR.TYPE='RRI';          
                elseif strncmp(ss,'Repo',4);	% Repo Holter Excel 2 file, not supported yet. 
                        HDR.TYPE='REPO';          
                elseif strncmp(ss,'Beat',4);	% Beat file % Holter Excel 2 file, not supported yet. 
                        HDR.TYPE='Beat';          
                elseif strncmp(ss,'Evnt',4);	% Event file % Holter Excel 2 file, not supported yet. 
                        HDR.TYPE='EVNT';          
                        
                elseif strncmp(ss,'CFWB',4); 	% Chart For Windows Binary data, defined by ADInstruments. 
                        HDR.TYPE='CFWB';
                elseif all(s==[abs('PLEXe'),zeros(1,127)]); 	% http://WWW.PLEXONINC.COM
                        HDR.TYPE='PLX';
                        
                elseif any(s(3:6)*(2.^[0;8;16;24]) == (30:40))
                        HDR.VERSION = s(3:6)*(2.^[0;8;16;24]);
                        offset2 = s(7:10)*(2.^[0;8;16;24]);
                        
                        if     HDR.VERSION < 34, offset = 150;
                        elseif HDR.VERSION < 35, offset = 164; 
                        elseif HDR.VERSION < 36, offset = 326; 
                        elseif HDR.VERSION < 38, offset = 886; 
                        else   offset = 1894; 
                        end;
                        if (offset==offset2),  
                                HDR.TYPE = 'ACQ';
                        end;
                        
                elseif all(s(1:4) == hex2dec(['FD';'AE';'2D';'05'])');
                        HDR.TYPE='AKO';
                elseif all(s(1:2)==[hex2dec('55'),hex2dec('AA')]);
                        HDR.TYPE='RDF';
                        
                elseif all(s(1:2)==[hex2dec('55'),hex2dec('3A')]);      % little endian 
                        HDR.TYPE='SEG2';
                        HDR.Endianity = 'ieee-le';
                elseif all(s(1:2)==[hex2dec('3A'),hex2dec('55')]);      % big endian 
                        HDR.TYPE='SEG2';
                        HDR.Endianity = 'ieee-be';
                        
                elseif strncmp(ss,'MATLAB Data Acquisition File.',29);  % Matlab Data Acquisition File 
                        HDR.TYPE='DAQ';
                elseif strncmp(ss,'MATLAB 5.0 MAT-file',19); 
                        HDR.TYPE='MAT5';
                        fseek(fid,126,'bof');
                        tmp = fread(fid,1,'uint16');
                        if tmp==(abs('MI').*[256,1])
                                HDR.Endianity = 'ieee-le';
                        elseif tmp==(abs('IM').*[256,1])
                                HDR.Endianity = 'ieee-be';
                        end;
                elseif strncmp(ss,'Model {',7); 
                        HDR.TYPE='MDL';
                        
                elseif any(s(1)==[49:51]) & all(s([2:4,6])==[0,50,0,0]) & any(s(5)==[49:50]),
                        HDR.TYPE = 'WFT';	% nicolet 	
                        
                elseif all(s(1:3)==[255,255,254]); 	% FREESURVER TRIANGLE_FILE_MAGIC_NUMBER
                        HDR.TYPE='FS3';
                elseif all(s(1:3)==[255,255,255]); 	% FREESURVER QUAD_FILE_MAGIC_NUMBER or CURVATURE
                        HDR.TYPE='FS4';
                elseif all(s(1:3)==[0,1,134]) & any(s(4)==[162:164]); 	% SCAN *.TRI file 
                        HDR.TYPE='TRI';
                elseif all((s(1:4)*(2.^[24;16;8;1]))==1229801286); 	% GE 5.X format image 
                        HDR.TYPE='5.X';
                        
                elseif all(s(1:2)==[105,102]); 
                        HDR.TYPE='669';
                elseif all(s(1:2)==[234,96]); 
                        HDR.TYPE='ARJ';
                elseif s(1)==2; 
                        HDR.TYPE='DB2';
                elseif any(s(1)==[3,131]); 
                        HDR.TYPE='DB3';
                elseif strncmp(ss,'DDMF',4); 
                        HDR.TYPE='DMF';
                elseif strncmp(ss,'DMS',4); 
                        HDR.TYPE='DMS';
                elseif strncmp(ss,'FAR',3); 
                        HDR.TYPE='FAR';
                elseif all(ss(5:6)==[175,18]); 
                        HDR.TYPE='FLC';
                elseif strncmp(ss,'GF1PATCH110',12); 
                        HDR.TYPE='GF1';
                elseif strncmp(ss,'GIF8',4); 
                        HDR.TYPE='GIF';
                elseif strncmp(ss,'CPT9FILE',8);        % Corel PhotoPaint Format
                        HDR.TYPE='CPT9';
                        
                elseif all(s(21:28)==abs('ACR-NEMA')); 
                        HDR.TYPE='ACR-NEMA';
                elseif all(s(1:132)==[zeros(1,128),abs('DICM')]); 
                        HDR.TYPE='DICOM';
                elseif all(s([2,4,6:8])==0) & all(s([1,3,5]));            % DICOM candidate
                        HDR.TYPE='DICOM';
                elseif all(s(1:18)==[8,0,5,0,10,0,0,0,abs('ISO_IR 100')])             % DICOM candidate
                        HDR.TYPE='DICOM';
                elseif all(s(12+[1:18])==[8,0,5,0,10,0,0,0,abs('ISO_IR 100')])             % DICOM candidate
                        HDR.TYPE='DICOM';
                elseif all(s([1:8,13:20])==[8,0,0,0,4,0,0,0,8,0,5,0,10,0,0,0])            % DICOM candidate
                        HDR.TYPE='DICOM';
                        
                elseif all(s([1:4])==[127,abs('ELF')])
                        HDR.TYPE='ELF';
                elseif all(s([1:4])==[77,90,192,0])
                        HDR.TYPE='EXE';
                elseif all(s([1:4])==[77,90,80,0])
                        HDR.TYPE='EXE/DLL';
                elseif all(s([1:4])==[77,90,128,0])
                        HDR.TYPE='DLL';
                elseif all(s([1:4])==[77,90,144,0])
                        HDR.TYPE='DLL';
                elseif all(s([1:8])==[254,237,250,206,0,0,0,18])
                        HDR.TYPE='MEXMAC';

                elseif all(s(1:24)==[208,207,17,224,161,177,26,225,zeros(1,16)]);	% MS-EXCEL candidate
                        HDR.TYPE='BIFF';
                        
                elseif all(s(1:2)==[255,254]) & all(s(4:2:end)==0)
                        HDR.TYPE='XML-UTF16';
                elseif ~isempty(findstr(ss,'?xml version'))
                        HDR.TYPE='XML-UTF8';

                elseif all(s([1:2,7:10])==[abs('BM'),zeros(1,4)])
                        HDR.TYPE='BMP';
                        HDR.Endianity = 'ieee-le';
                elseif strncmp(ss,'SIMPLE  =                    T / Standard FITS format',30)
                        HDR.TYPE='FITS';
                elseif strncmp(ss,'CDF',3)
                        HDR.TYPE='NETCDF';
                elseif strncmp(ss,'.PBF',4)      
                        HDR.TYPE='PBF';
                elseif all(s(1:2)=='P6') & any(s(3)==[10,13])
                        HDR.TYPE='PNG6';
                elseif all(s(1:8)==[137,80,78,71,13,10,26,10]) 
                        HDR.TYPE='PNG';
                elseif all(s(1:4)==hex2dec(['FF';'D9';'FF';'E0'])')
                        HDR.TYPE='JPG';
                        HDR.Endianity = 'ieee-be';
                elseif all(s(1:4)==hex2dec(['FF';'D8';'FF';'E0'])')
                        HDR.TYPE='JPG';
                        HDR.Endianity = 'ieee-be';
                elseif all(s(1:4)==hex2dec(['E0';'FF';'D8';'FF'])')
                        HDR.TYPE='JPG';
                        HDR.Endianity = 'ieee-le';
                elseif all(s(1:20)==['L',0,0,0,1,20,2,0,0,0,0,0,192,0,0,0,0,0,0,70])
                        HDR.TYPE='LNK';
                        tmp = fread(fid,inf,'char');
                        HDR.LNK=[s,tmp'];
                elseif all(s(1:3)==[0,0,1])	
                        HDR.TYPE='MPG2MOV';
                elseif strcmp(ss([3:5,7]),'-lh-'); 
                        HDR.TYPE='LZH';
                elseif strcmp(ss([3:5,7]),'-lz-'); 
                        HDR.TYPE='LZH';
                elseif strcmp(ss(1:3),'MMD'); 
                        HDR.TYPE='MED';
                elseif (s(1)==255) & any(s(2)>=224); 
                        HDR.TYPE='MPEG';
                elseif strncmp(ss(5:8),'mdat',4); 
                        HDR.TYPE='MOV';
                elseif all(s(1:2)==[26,63]); 
                        HDR.TYPE='OPT';
                elseif strncmp(ss,'%PDF',4); 
                        HDR.TYPE='PDF';
                elseif strncmp(ss,'QLIIFAX',7); 
                        HDR.TYPE='QFX';
                elseif strncmp(ss,'.RMF',4); 
                        HDR.TYPE='RMF';
                elseif strncmp(ss,'IREZ',4); 
                        HDR.TYPE='RMF';
                elseif strncmp(ss,'{\rtf',5); 
                        HDR.TYPE='RTF';
                elseif strncmp(ss,'II',2); 
                        HDR.TYPE='TIFF';
                        HDR.Endianity = 0;
                elseif strncmp(ss,'MM',2); 
                        HDR.TYPE='TIFF';
                        HDR.Endianity = 1;
                elseif strncmp(ss,'StockChartX',11); 
                        HDR.TYPE='STX';
                elseif all(ss(1:2)==[25,149]); 
                        HDR.TYPE='TWE';
                elseif strncmp(ss,'#VRML',5); 
                        HDR.TYPE='VRML';
                elseif strncmp(ss,'# vtk DataFile Version',20); 
                        HDR.TYPE='VTK';
                elseif all(ss(1:5)==[0,0,2,0,4]); 
                        HDR.TYPE='WKS';
                elseif all(ss(1:5)==[0,0,2,0,abs('Q')]); 
                        HDR.TYPE='WQ1';
                elseif all(s(1:8)==hex2dec(['30';'26';'B2';'75';'8E';'66';'CF';'11'])'); 
                        HDR.TYPE='WMV';
                        
                	% compression formats        
                elseif strncmp(ss,'BZh91AH&SY',10); 
                        HDR.TYPE='BZ2';
                elseif all(s(1:3)==[66,90,104]); 
                        HDR.TYPE='BZ2';
                elseif strncmp(ss,'MSCF',4); 
                        HDR.TYPE='CAB';
                elseif all(s(1:3)==[31,139,8]); 
                        HDR.TYPE='gzip';
                elseif all(s(1:3)==[31,157,144]); 
                        HDR.TYPE='Z';
                elseif all(s([1:4])==[80,75,3,4]) & (c>=30)
                        HDR.TYPE='ZIP';
                        HDR.Version = s(5:6)*[1;256];
                        HDR.ZIP.FLAG = s(7:8);
                        HDR.ZIP.CompressionMethod = s(9:10);
                        
                        % converting MS-Dos Date*Time format
                        tmp = s(11:14)*2.^[0:8:31]';
                        HDR.T0(6) = rem(tmp,2^5)*2;	tmp=floor(tmp/2^5);
                        HDR.T0(5) = rem(tmp,2^6);	tmp=floor(tmp/2^6);
                        HDR.T0(4) = rem(tmp,2^5);	tmp=floor(tmp/2^5);
                        HDR.T0(3) = rem(tmp,2^5);	tmp=floor(tmp/2^5);
                        HDR.T0(2) = rem(tmp,2^4); 	tmp=floor(tmp/2^4);
                        HDR.T0(1) = 1980+tmp; 
                        
                        HDR.ZIP.CRC = s(15:18)*2.^[0:8:31]';
                        HDR.ZIP.size2 = s(19:22)*2.^[0:8:31]';
                        HDR.ZIP.size1 = s(23:26)*2.^[0:8:31]';
                        HDR.ZIP.LengthFileName = s(27:28)*[1;256];
                        HDR.ZIP.filename = char(s(31:min(c,30+HDR.ZIP.LengthFileName)));
                        HDR.ZIP.LengthExtra = s(29:30)*[1;256];
                        HDR.HeadLen = 30 + HDR.ZIP.LengthFileName + HDR.ZIP.LengthExtra;
                        HDR.tmp = char(s);
                        HDR.ZIP.Extra = s(31+HDR.ZIP.LengthFileName:min(c,HDR.HeadLen));
                        if strncmp(ss(31:end),'mimetypeapplication/vnd.sun.xml.writer',38)
                                HDR.TYPE='SWX';
                        end;
                elseif strncmp(ss,'ZYXEL',5); 
                        HDR.TYPE='ZYXEL';
                elseif strcmpi(HDR.FILE.Name,ss(1:length(HDR.FILE.Name)));
                        HDR.TYPE='HEA';
                        
                elseif all(s(1:16)==[1,0,0,0,1,0,0,0,4,0,0,0,0,0,0,0]),  % should be last, otherwise to many false detections
                        HDR.TYPE='MAT4';
                        HDR.MAT4.opentyp='ieee-be';
			
                        %elseif all(~type_mat4),  % should be last, otherwise to many false detections
                elseif all(s(1:4)==0),  % should be last, otherwise to many false detections
                        HDR.TYPE='MAT4';
                        if type_mat4(1)==1,
                                HDR.MAT4.opentyp='ieee-be';
                        elseif type_mat4(1)==2,
                                HDR.MAT4.opentyp='vaxd';
                        elseif type_mat4(1)==3,
                                HDR.MAT4.opentyp='vaxg';
                        elseif type_mat4(1)==4,
                                HDR.MAT4.opentyp='gray';
                        else
                                HDR.MAT4.opentyp='ieee-le';
                        end;
                        
                elseif ~isempty(findstr(ss,'### Table of event codes.'))
                        fseek(fid,0,-1);
                        line = fgetl(fid);
                        N = 1;
                        while length(line),
                                if (line(1)~='#'),
                                        [ix,desc] = strtok(line,char([9,32,13,10]));
                                        ix = hex2dec(ix(3:end));
                                        HDR.EVENT.CodeDesc{N,1} = desc(2:end);
                                        HDR.EVENT.CodeIndex(N,1) = ix;
                                        N = N + 1;
                                end;	
                                line = fgetl(fid);
                        end;
                        HDR.TYPE = 'EVENTCODES';
                else
                        HDR.TYPE='unknown';

                        status = fseek(fid,3228,-1);
                        [s0,c]=fread(fid,[1,4],'uint8'); 
			if (status & (c==4)) 
			if all((s0(1:4)*(2.^[24;16;8;1]))==1229801286); 	% GE LX2 format image 
                                HDR.TYPE='LX2';
                        end;
			end;
                end;
        end;
        fclose(fid);
        
        
        if strcmpi(HDR.TYPE,'unknown'),
                % alpha-TRACE Medical software
                if (strcmpi(HDR.FILE.Name,'rawdata') | strcmpi(HDR.FILE.Name,'rawhead')) & isempty(HDR.FILE.Ext),
                        if exist(fullfile(HDR.FILE.Path,'digin'),'file') & exist(fullfile(HDR.FILE.Path,'r_info'),'file');	
                                HDR.TYPE = 'alpha'; %alpha trace medical software 
                        end;
                end;
                TYPE = [];
                
                %%% this is the file type check based on the file extionsion, only.  
                if 0, 
                        
                        % MIT-ECG / Physiobank format
                elseif strcmpi(HDR.FILE.Ext,'HEA'), HDR.TYPE='MIT';
                        
                elseif strcmpi(HDR.FILE.Ext,'DAT') | strcmpi(HDR.FILE.Ext,'ATR'), 
                        tmp = dir(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.hea']));
                        if isempty(tmp), 
                                tmp = dir(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.HEA']));
                        end
                        if ~isempty(tmp), 
                                HDR.TYPE='MIT';
                                [tmp,tmp1,tmp2] = fileparts(tmp.name);
                                HDR.FILE.Ext = tmp2(2:end);
                        end
                        
                elseif strcmpi(HDR.FILE.Ext,'rhf'),
                        HDR.FileName=fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.',HDR.FILE.Ext]);
                        HDR.TYPE = 'RG64';
                elseif strcmp(HDR.FILE.Ext,'rdf'),
                        HDR.FileName=fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.',HDR.FILE.Ext(1),'h',HDR.FILE.Ext(3)]);
                        HDR.TYPE = 'RG64';
                elseif strcmp(HDR.FILE.Ext,'RDF'),
                        HDR.FileName=fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.',HDR.FILE.Ext(1),'H',HDR.FILE.Ext(3)]);
                        HDR.TYPE = 'RG64';
                        
                elseif strcmpi(HDR.FILE.Ext,'hdm')
                        
                elseif strcmpi(HDR.FILE.Ext,'hc')
                        
                elseif strcmpi(HDR.FILE.Ext,'shape')
                        
                elseif strcmpi(HDR.FILE.Ext,'shape_info')
                        
                elseif strcmpi(HDR.FILE.Ext,'trg')
                        
                elseif strcmpi(HDR.FILE.Ext,'rej')
                        
                elseif strcmpi(HDR.FILE.Ext,'elc')
                        
                elseif strcmpi(HDR.FILE.Ext,'vol')
                        
                elseif strcmpi(HDR.FILE.Ext,'bnd')
                        
                elseif strcmpi(HDR.FILE.Ext,'msm')
                        
                elseif strcmpi(HDR.FILE.Ext,'msr')
                        HDR.TYPE = 'ASA2';    % ASA version 2.x, see http://www.ant-software.nl
                        
                elseif strcmpi(HDR.FILE.Ext,'dip')
                        
                elseif strcmpi(HDR.FILE.Ext,'mri')
                        
                elseif strcmpi(HDR.FILE.Ext,'iso')
                        
                elseif strcmpi(HDR.FILE.Ext,'hdr')
                        
                elseif strcmpi(HDR.FILE.Ext,'img')
                        
                        % the following are Brainvision format, see http://www.brainproducts.de
                elseif strcmpi(HDR.FILE.Ext,'vhdr')
                        HDR.TYPE = 'BrainVision';    % Brainvision EEG header file
                        
                elseif strcmpi(HDR.FILE.Ext,'vmrk')
                        HDR.TYPE = 'BrainVision';    % Brainvision EEG marker/event file
                        
                elseif strcmpi(HDR.FILE.Ext,'eeg')
                        % If this is really a BrainVision file, there should also be a
                        % header with the same name and extension *.vhdr.
                        if exist(fullfile(HDR.FILE.Path, [HDR.FILE.Name '.vhdr']), 'file')
                                HDR.TYPE          = 'BrainVision';
                                HDR.FileName = fullfile(HDR.FILE.Path, [HDR.FILE.Name '.vhdr']);	% point to header file
                        end
                        
                elseif strcmpi(HDR.FILE.Ext,'seg')
                        % If this is really a BrainVision file, there should also be a
                        % header with the same name and extension *.vhdr.
                        if exist(fullfile(HDR.FILE.Path, [HDR.FILE.Name '.vhdr']), 'file')
                                HDR.TYPE          = 'BrainVision';
                                HDR.FileName = fullfile(HDR.FILE.Path, [HDR.FILE.Name '.vhdr']);	% point to header file
                        end
                        
                elseif strcmpi(HDR.FILE.Ext,'vabs')
                                                
                elseif strcmpi(HDR.FILE.Ext,'bni')        %%% Nicolet files 
                        HDR = getfiletype(fullfile(HDR.FILE.Path, [HDR.FILE.Name '.eeg']));
                        
                elseif strcmpi(HDR.FILE.Ext,'eeg')        %%% Nicolet files 
                        fn = fullfile(HDR.FILE.Path, [HDR.FILE.Name '.bni']);
                        if exist(fn, 'file')
                                fid = fopen(fn,'r','ieee-le');
                                HDR.Header = char(fread(fid,[1,inf],'uchar'));
                                fclose(fid);
                        end;
                        if exist(HDR.FileName, 'file')
                                fid = fopen(HDR.FileName,'r','ieee-le');
                                fseek(fid,-4,'eof');
                                datalen = frea(fid,1,'uint32');
                                fseek(fid,datalen,'bof');
                                HDR.Header = char(fread(fid,[1,inf],'uchar'));
                                fclose(fid);
                        end;
                        pos_rate = strfind(HDR.Header,'Rate =');
                        pos_nch  = strfind(HDR.Header,'NchanFile =');
                        
                        if ~isempty(pos_rate) & ~isempty(pos_nch),
                                HDR.SampleRate = str2double(HDR.Header(pos_rate + (6:9)));
                                HDR.NS = str2double(HDR.Header(pos_nch +(11:14)));
                                HDR.SPR = datalen/(2*HDR.NS);
                                HDR.AS.endpos = HDR.SPR;
                                HDR.GDFTYP = 3; % int16;
                                HDR.HeadLen = 0; 
                                HDR.TYPE = 'Nicolet';  
                        end;
                        
                        
                elseif strcmpi(HDR.FILE.Ext,'fif')
                        HDR.TYPE = 'FIF';	% Neuromag MEG data (company is now part of 4D Neuroimaging)
                        
                elseif strcmpi(HDR.FILE.Ext,'bdip')
                        
                elseif strcmpi(HDR.FILE.Ext,'elp')
                        
                elseif strcmpi(HDR.FILE.Ext,'sfp')
                        
                elseif strcmpi(HDR.FILE.Ext,'ela')
                        
                elseif strcmpi(HDR.FILE.Ext,'trl')
                        
                elseif (length(HDR.FILE.Ext)>2) & all(s>31),
                        if all(HDR.FILE.Ext(1:2)=='0') & any(abs(HDR.FILE.Ext(3))==abs([48:57])),	% WSCORE scoring file
                                x = load('-ascii',HDR.FileName);
                                HDR.EVENT.N   = size(x,1);
                                HDR.EVENT.POS = x(:,1);
                                HDR.EVENT.TYP = x(:,2);
                                HDR.TYPE = 'EVENT';
                        end;
                end;
        end;
        
        if 0, strcmpi(HDR.TYPE,'unknown'),
                try
                        [status, HDR.XLS.sheetNames] = xlsfinfo(HDR.FileName)
                        if ~isempty(status)
                                HDR.TYPE = 'EXCEL';
                        end;
                catch
                end;
        end;
end;
