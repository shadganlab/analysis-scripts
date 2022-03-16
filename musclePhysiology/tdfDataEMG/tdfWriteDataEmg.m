function res = tdfWriteDataEmg (filename,startTime,frequency,emgMap,labels,emgData,varargin)
%TDFWRITEDATAEMG   Write EMG Data to TDF-file.
%   RES = TDFWRITEDATAEMG (FILENAME,STARTTIME,FREQUENCY,EMGMAP,LABELS,EMGDATA) writes 
%   to FILENAME the EMG data sampling start time ([s]) and sampling rate ([Hz]),
%   the correspondance map between EMG logical channels and physical channels stored
%   in EMGMAP, the EMG channel labels stored in LABELS and the EMG data stored in EMGDATA.
%   EMGMAP must be a [nSignals,1] array such that EMGMAP(logical channel) == physical channel.
%   LABELS must be a matrix whose rows are the EMG channel labels.
%   EMGDATA must be an array of size nSignals x nSamples such that
%   EMGDATA(s,:) stores the samples of the EMG channel s. 
%
%   res = TDFWRITEDATAEMG (...,FORMAT) specifies the format for the EMG data block.
%   Valid entries for FORMAT are 'bytrack' (default), 'byframe'.
%   See Tdf File format documentation for further details.
%
%   If the file specified does not exist, a new one is created.
%   RES is 0 in case of success, -1 otherwise.
%
%   See also TDFREADDATAEMG
%
%   Copyright (c) 2000 by BTS S.p.A.
%   $Revision: 2 $ $Date: 14/07/06 11.43 $

if (nargin == 6)
   strFormat   = 'bytrack';
else
   strFormat   = varargin{1};
end

switch strFormat
case 'bytrack'
   blockFormat = 1;
case 'byframe'
   blockFormat = 2;
otherwise
   disp ('Error: invalid block format')
   return
end

tdfDataEmgBlockId = 11;
res = -1;

[fid,entryOffset,blockOffset] = tdfFileTest (filename,tdfDataEmgBlockId);
if fid == -1
   return
end

if (-1 == fseek (fid,blockOffset,'bof'))
   disp ('Error: the file specified is corrupted.')
   tdfFileClose (fid);
   return
end

nSignals = length (emgMap);
nSamples = size (emgData,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write header information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fwrite (fid,nSignals,'int32');
fwrite (fid,frequency,'int32');
fwrite (fid,startTime,'float32');
fwrite (fid,nSamples,'int32');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write EMG map information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fwrite (fid,emgMap,'int16');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write EMG data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labelsToWrite = char (zeros (nSignals,256));
labelLen = size (labels,2);
for l = 1 : size (labels,1)
   labelsToWrite(l,1:labelLen) = labels(l,:);
end

if (1 == blockFormat)
   for e = 1 : nSignals
      fwrite (fid,labelsToWrite(e,:),'char');
      invalidFrames = cat(2,0,find (~isfinite (emgData(e,:))),nSamples+1);
      segLens = diff (invalidFrames)-1;
      segments = cat (1,invalidFrames (find (segLens>0)),segLens (find (segLens>0)));
      nSegments = size (segments,2);
      fwrite (fid,nSegments,'int32');
      fwrite (fid,0,'uint32');
      fwrite (fid,segments,'int32');
      for s = 1 : nSegments
         fwrite (fid,emgData(e,segments(1,s)+1 : (segments(1,s)+segments(2,s))),'float32');
      end
   end
elseif (2 == blockFormat)
   for e = 1 : nSignals
      fwrite (fid,labelsToWrite(e,:),'char');
   end
   fwrite (fid,emgData','float32');
end   

newBlockOffset = ftell (fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write entry information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fseek (fid,entryOffset,'bof');
fwrite (fid,tdfDataEmgBlockId,'uint32');
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


