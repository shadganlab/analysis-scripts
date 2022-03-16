%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%

function [] = tdfFileFinalize (fid,blockOffset)

if (fid == -1)
   disp ('Error: invalid fid.')
   return
end

frewind (fid);
fseek (fid,20,'bof');
nEntries = fread (fid,1,'int32');
fseek (fid,40,'cof');
for e = 1:nEntries
   blockType = fread (fid,1,'uint32');
   fseek (fid,4,'cof');                %format
   if (0 == blockType)
      fwrite (fid,blockOffset,'int32');
   else
      fseek (fid,4,'cof');
   end
   fseek (fid,276,'cof');
end

fclose (fid);

