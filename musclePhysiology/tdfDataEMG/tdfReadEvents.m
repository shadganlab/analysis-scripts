function [nEvents,labels, evnType, evnData] = tdfReadEvents (filename)
%TDFREADEVENTS   Read events data from TDF-file.
%   [NEVENTS,LABELS,EVNDATA] = TDFREADEVENTS (FILENAME) retrieves from FILENAME
%   Events Data and stores it in EVNDATA.
%   EVNTYPE is a [NEVENTS,1] matrix with the type of the event, 
%   single event(0) or event sequence (1).
%   LABELS is a [NEVENTS,1] matrix with the text strings of the event as rows.
%   EVNDATA is a {NEVENTS} cell array such that EVNDATA{e} is the item sequence of the event E.
%   See also TDFWRITEEVENTS.
%
%   Copyright (c) 2000 by BTS S.p.A.
%   $Revision: 1 $ $Date: 5/11/10 14.55 $

nEvents = 0;
labels = [];
evnType = [];
evnData = [];

[fid,tdfBlockEntries] = tdfFileOpen (filename);   % open the file
if fid == -1
   return
end

tdfEventsBlockId = 16;
blockIdx = 0;
for e = 1 : length (tdfBlockEntries)
   if (tdfEventsBlockId == tdfBlockEntries(e).Type) & (0 ~= tdfBlockEntries(e).Format)
      blockIdx = e;
      break
   end
end
if blockIdx == 0
   disp ('Events not found in the file specified.')
   tdfFileClose (fid);
   return
end

if (-1 == fseek (fid,tdfBlockEntries(blockIdx).Offset,'bof'))
   disp ('Error: the file specified is corrupted.')
   tdfFileClose (fid);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read header information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nEvents       = fread (fid,1,'int32');
startTime     = fread (fid,1,'float32');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read events data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labels  = char (zeros (nEvents,256));
nItems  = zeros (nEvents);
%emgData = NaN * ones(nSignals,nSamples);
evnData    = cell (nEvents);

if (1 == tdfBlockEntries(blockIdx).Format)         % std
   
  for e = 1 : nEvents
      label      = strtok (char ((fread (fid,256,'uchar'))'), char (0));
      labels (e,1:length (label)) = label;
      evnType (e) = fread (fid,1,'int32');
      nItems (e) = fread (fid,1,'int32');
      evnData {e} = fread (fid,nItems (e),'float32');
   end
      
end

tdfFileClose (fid);                               % close the file

   