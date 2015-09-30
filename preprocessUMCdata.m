function preprocessUMCdata(folder, options)
    % Function to convert output from Philips 7T scanner to a format
    % mrVista can handle
    %
    % INPUT:
    %
    %   - folder: the folder where the mrVista session should be (optional)
    %             default = pwd
    %   - options: a struct containing the options for R2A (optional)
    %             default = default settings listed below
    %
    % NOTE: the script assumes that there will be a subfolder called
    % 'Scanner output' containing your PAR files inside the folder. If this
    % is not the case the script will NOT WORK.
    %

    if ~exist('folder','var') || isempty(folder)
        folder = pwd;
    end    
    
    % Reference for options struct
    % options: structure containing options for conversion. Fields:
    % options.prefix       : characters to prepend to all output folder and filenames,
    %                         use '' when not needed. Cell array of prefixes
    %                         can be used to use different prefix for each
    %                         corresponding file in filelist.
    % options.usefullprefix: when 1, do not append PARfilename to output files, use
    %                        prefix only, plus filenumber
    % options.pathpar      : complete path containing PAR files (with trailing /)
    % options.subaan       : when 1 checked, files will be written in a different
    %                        subdirectory per PAR file, otherwise all to pathpar
    % options.usealtfolder : when 1, files will be written to
    %                        options.altfolder, including lowest level folder
    %                        containing parfile
    % options.altfolder    : see above
    % options.outputformat : 1 for Nifty output format (spm5), 2 for Analyze (spm2)
    % options.angulation   : when 1: include affine transformation as defined in PAR
    %                        file in hdr part of Nifti file (nifti only, EXPERIMENTAL!)
    % options.rescale      : when 1: store intensity scale as found in PAR
    %                        file (assumed equall for all slices). Yields DV values.
    % options.dim          : when 3, single 3D nii files will be produced, when
    %                        4, one 4D nii file will be produced, for example
    %                        for time series or dti data
    % options.dti_revertb0 : when 0 (default), philips ordering is used for DTI data
    %                       (eg b0 image last). When 1, b0 is saved as first image in 3D or 4D data    
    
    if ~exist('options','var') || isempty(options)
        options.prefix = '';
        options.usefullprefix = 0;
        options.pathpar = [folder filesep 'Scanner output/'];
        options.subaan = 1;
        options.usealtfolder = 0;
        options.altfolder = '';% [pwd '/Raw/'];
        options.outputformat = 1;
        options.angulation = 1;
        options.rescale = 0;
        options.dim = 4;        
    end
    
    % Locate functional scans
    disp('Locating functional (EPI) scan files');
    files = dir([folder filesep 'Scanner output/*_32ch_*.PAR']);

    fileList = [];

    if ~isempty(files)
        for fii = 1:length(files)
            fileList{fii} = files(fii).name;
        end
    end

    % Same for anatomical (both inplane & whole brain)
    disp('Locating anatomical (T1) scan files');
    files = dir([folder filesep 'Scanner output/*T1*.PAR']);

    if ~isempty(files)
        for fii = 1:length(files)
            fileList{end+1} = files(fii).name;
        end
    end

    disp('Converting PAR files to NIFTI');
    convert_r2a(fileList, options);

    if ~exist([folder filesep 'Raw/'],'dir')
        mkdir(folder,'Raw');
    end

    %cd([pwd '/Scanner output/']);
    for file = 1:length(fileList)
        disp('Moving files to Raw folder');
        [~,filename, ~] = fileparts(fileList{file});

        %cd(filename);

        movefile([folder filesep 'Scanner output' filesep filename filesep filename '*.nii'],'Raw/');

        %   disp(filename);
    end


    % Permute dimensions of nifti files into mrVista format
    disp('Rotating niftis to mrVista orientation');
    niiFiles = dir([folder filesep 'Raw' filesep '*.nii']);

    for nii = 1:length(niiFiles)

        tmpFile = niftiRead([folder filesep 'Raw' filesep niiFiles(nii).name]);
        copyfile([folder filesep 'Raw' filesep niiFiles(nii).name], [folder filesep 'Raw' filesep niiFiles(nii).name '.bak']);

        if length(size(tmpFile.data))==4
            tmpFile.data = permute(tmpFile.data, [2 1 3 4]);
        else
            tmpFile.data = permute(tmpFile.data, [2 1 3]);
        end

        niftiWrite(tmpFile);

    end

    disp('Done');
end
