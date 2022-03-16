%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%

function [fid,entryOffset,blockOffset] = tdfFileTest (tdfFilename,tdfBlockType)

tdfBlockEntries = struct ( ...
   'Type',{}, ...
   'Format',{}, ...
   'Offset',{}, ...
   'Size',{});

fid = -1;
blockOffset = -1;
entryOffset = -1;

if (2 > tdfBlockType) | (15 < tdfBlockType)
   disp ('invalid block type')
   return
end

tdfSignature = '41604B82CA8411D3ACB60060080C6816';

fid = fopen (tdfFilename,'r');            % try to open the file in read mode
if fid == -1                              % file not found? file already open?
   [fid,msg] = fopen (tdfFilename,'w+');  % try to create a new file
   if fid == -1
      disp (msg)
      return
   end
   nEntries = 14;
   disp ('file not found. A new file has been created')
   fwrite (fid,hex2dec (tdfSignature(1:8)),'uint32');
   fwrite (fid,hex2dec (tdfSignature(9:16)),'uint32');
   fwrite (fid,hex2dec (tdfSignature(17:24)),'uint32');
   fwrite (fid,hex2dec (tdfSignature(25:32)),'uint32');
   fwrite (fid,1,'uint32');               %version
   fwrite (fid,nEntries,'int32');
   fwrite (fid,0,'uint32');               %Reserved
   fwrite (fid,0,'uint32');               %Reserved
   tdfTime = (now - datenum ('02-Jan-1970 00:00:00') ) * 24 * 60 * 60;
   fwrite (fid,tdfTime,'int32');
   fwrite (fid,tdfTime,'int32');
   fwrite (fid,tdfTime,'int32');
   fwrite (fid,0,'uint32');               %Reserved
   fwrite (fid,0,'uint32');               %Reserved
   fwrite (fid,0,'uint32');               %Reserved
   fwrite (fid,0,'uint32');               %Reserved
   fwrite (fid,0,'uint32');               %Reserved
   
   entryOffset = 64;
   blockOffset = entryOffset + 288*nEntries;
   
   for e = 1:nEntries
      fwrite (fid,0,'uint32');            %type
      fwrite (fid,0,'uint32');            %format
      fwrite (fid,blockOffset,'int32');
      fwrite (fid,0,'int32');             %size
      fwrite (fid,tdfTime,'int32');
      fwrite (fid,tdfTime,'int32');
      fwrite (fid,tdfTime,'int32');
      fwrite (fid,0,'uint32');            %Reserved
      fwrite (fid,char (zeros (1,256)),'char');
   end
   
else
   ID = dec2hex (fread (fid,1,'uint32'),8); % check the ID
   for i = 1:3
      ID = strcat (ID,dec2hex (fread (fid,1,'uint32'),8));
   end
   if ~strcmp (ID,tdfSignature)
      disp ('Error: invalid binary file.')
      fclose (fid);
      fid = -1;
      return
   end
   version = fread (fid,1,'uint32');
   nEntries = fread (fid,1,'int32');
   tdfBlockEntries = struct ( ...
      'Type',cell (1,nEntries), ...
      'Format',cell (1,nEntries), ...
      'Offset',cell (1,nEntries), ...
      'Size',cell (1,nEntries), ...
      'MoreData',cell (1,nEntries));
   tdfNewBlockEntries = tdfBlockEntries;
   
   if (-1 == fseek (fid,40,'cof'))
      disp ('Error: the file specified is corrupted.');
      fclose (fid);
      fid = -1;
      return
   end
   
   nValidEntries = 0;
   newBlockOffset = 0;
   blockToDel = 0;
   blockToDelSize = 0;
   blockToDelOffset = 0;
   headerSize = ftell (fid);
   for e = 1:nEntries
      tdfBlockEntries(e).Type       = fread (fid,1,'uint32');
      tdfBlockEntries(e).Format     = fread (fid,1,'uint32');
      tdfBlockEntries(e).Offset     = fread (fid,1,'int32');
      tdfBlockEntries(e).Size       = fread (fid,1,'int32');
      tdfBlockEntries(e).MoreData   = fread (fid,68,'uint32');
      if (tdfBlockEntries(e).Offset + tdfBlockEntries(e).Size > newBlockOffset)
         newBlockOffset = tdfBlockEntries(e).Offset + tdfBlockEntries(e).Size;
      end
      if (tdfBlockType == tdfBlockEntries(e).Type)
         button = questdlg('A data block of the type specified already exists. Overwrite?',...
            'Overwriting file','Yes','No','No');
         if strcmp (button,'No')
            fclose (fid);
            fid = -1;
            return
         end
         blockToDel = e;
         blockToDelOffset = tdfBlockEntries(e).Offset;
         blockToDelSize = tdfBlockEntries(e).Size;
      elseif (0 < tdfBlockEntries(e).Type)
         nValidEntries = nValidEntries + 1;
         tdfNewBlockEntries(nValidEntries) = tdfBlockEntries(e);
         if (0 ~= blockToDel)
            tdfNewBlockEntries(nValidEntries).Offset = ...
               tdfNewBlockEntries(nValidEntries).Offset - blockToDelSize;
         end
      end
   end
   dataOffset = ftell (fid);
   
   if (nEntries == nValidEntries)
      disp ('the file specified cannot contain more data.')
      fclose (fid);
      fid = -1;
      return
   end
   
   frewind (fid);
   headerNDWords = floor (headerSize/4);
   headerNBytes = rem (headerSize,4);
   headerDWords = fread (fid,headerNDWords,'uint32');
   headerBytes = fread (fid,headerNBytes,'uchar');
   
   fseek (fid,dataOffset,'bof');
   
   moreDataSize = 0;
   if (0 ~= blockToDel)
      dataSize = blockToDelOffset - dataOffset;
      dataNDWords = floor (dataSize/4);
      dataNBytes = rem (dataSize,4);
      dataDWords = fread (fid,dataNDWords,'uint32');
      dataBytes = fread (fid,dataNBytes,'uchar');
      fseek (fid,blockToDelSize,'cof');
      newBlockOffset = newBlockOffset - blockToDelSize;
      moreDataSize = newBlockOffset - blockToDelOffset;
      moreDataNDWords = floor (moreDataSize/4);
      moreDataNBytes = rem (moreDataSize,4);
      moreDataDWords = fread (fid,moreDataNDWords,'uint32');
      moreDataBytes = fread (fid,moreDataNBytes,'uchar');
   else
      dataSize = newBlockOffset - dataOffset;
      dataNDWords = floor (dataSize/4);
      dataNBytes = rem (dataSize,4);
      dataDWords = fread (fid,dataNDWords,'uint32');
      dataBytes = fread (fid,dataNBytes,'uchar');
   end
   
   fclose (fid);
   [fid,msg] = fopen (tdfFilename,'w+');
   if fid == -1
      disp (msg)
      return
   end
   frewind (fid);
   
   fwrite (fid,headerDWords,'uint32');
   fwrite (fid,headerBytes,'uchar');
   for e = 1 : nValidEntries
      fwrite (fid,tdfNewBlockEntries(e).Type,'uint32');
      fwrite (fid,tdfNewBlockEntries(e).Format,'uint32');
      fwrite (fid,tdfNewBlockEntries(e).Offset,'int32');
      fwrite (fid,tdfNewBlockEntries(e).Size,'int32');
      fwrite (fid,tdfNewBlockEntries(e).MoreData,'uint32');
   end
   entryOffset = ftell (fid);
   for e = nValidEntries+1 : nEntries
      fwrite (fid,0,'uint32');
      fwrite (fid,0,'uint32');
      fwrite (fid,newBlockOffset,'int32');
      fwrite (fid,0,'int32');
      fwrite (fid,zeros (68,1),'uint32');
   end
   fwrite (fid,dataDWords,'uint32');
   fwrite (fid,dataBytes,'uchar');
   if (moreDataSize > 0)
      fwrite (fid,moreDataDWords,'uint32');
      fwrite (fid,moreDataBytes,'uchar');
   end
   
   blockOffset = newBlockOffset;
   
end

frewind (fid);
