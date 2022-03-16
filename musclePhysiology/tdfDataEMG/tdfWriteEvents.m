function res = tdfWriteEvents (filename,startTime,labels,evnType,evnData,varargin)
%TDFWRITEEVENTS   Write Events to TDF-file.
%   RES = TDFWRITEEVENTS (FILENAME,STARTTIME,LABELS,EVNTYPE,EVNDATA) writes 
%   to FILENAME the events stored in EVNDATA, with type in EVNTYPE.
%   All the arguments must have the same structure as the ones retrieved by TDFREADEVENTS.
%
%   res = TDFWRITEEVENTS (...,FORMAT) specifies the format for the EMG data block.
%   Valid entries for FORMAT are 'std'. 
%   See Tdf File format documentation for further details.
%
%   If the file specified does not exist, a new one is created.
%   RES is 0 in case of success, -1 otherwise.
%
%   See also TDFREADEVENTS
%
%   Copyright (c) 2000 by BTS S.p.A.
%   $Revision: 1 $ $Date: 5/11/10 14.55 $

if (nargin == 5)
   strFormat   = 'std';
else
   strFormat   = varargin{1};
end

switch strFormat
case 'std'
   blockFormat = 1;
otherwise
   disp ('Error: invalid block format')
   return
end

tdfEventsBlockId = 16;
res = -1;

[fid,entryOffset,blockOffset] = tdfFileTest (filename,tdfEventsBlockId);
if fid == -1
   return
end

if (-1 == fseek (fid,blockOffset,'bof'))
   disp ('Error: the file specified is corrupted.')
   tdfFileClose (fid);
   return
end

nEvents     = size (evnData,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write header information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fwrite (fid,nEvents,'int32');
fwrite (fid,startTime,'float32');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write EVENT data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labelsToWrite = char (zeros (nEvents,256));
labelLen = size (labels,2);
for l = 1 : size (labels,1)
   labelsToWrite(l,1:labelLen) = labels(l,:);
end

if (1 == blockFormat)
   for e = 1 : nEvents
      fwrite (fid,labelsToWrite(e,:),'char');
      fwrite (fid,evnType(e),'uint32');
      fwrite (fid,size(evnData{e},1),'int32');
      fwrite (fid,evnData{e},'float32');
   end
end   

newBlockOffset = ftell (fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write entry information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fseek (fid,entryOffset,'bof');
fwrite (fid,tdfEventsBlockId,'uint32');
fwrite (fid,blockFormat,'uint32');
fwrite (fid,blockOffset,'int32');
fwrite (fid,newBlockOffset-blockOffset,'int32');
tdfTime = (now - datenum ('02-Jan-1970 00:00:00') ) * 24 * 60 * 60;
fwrite (fid,tdfTime,'int32');
fwrite (fid,tdfTime,'int32');
fwrite (fid,tdfTime,'int32');
fwrite (fid,0,'uint32');
fwrite (fid,char (zeros (1,256)),'char');

tdfFileFinalize (fid,newBlockOffset);             % close the file
res = 0;


