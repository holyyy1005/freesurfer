% Clean up
close all
clear all



%
%
% 1. partialVolumeStats.txt
%
%    generated by running quantifyResults.sh
% 
%    FORMAT:
%        volume_in_number_of_voxels   Right-Hippocampus   right_presubiculum   right_CA1   right_CA2-3   right_fimbria right_subiculum   right_CA4-DG   right_hippocampal_fissure
%        080207_4TT00446    434.903    447.049    362.978    1117.21    47.8863    693.93    600.351    25.498
%        080306_4TT00468    366.385    428.586    293.825    968.467    54.9529    521.613    527.622    60.2705
%        ...
%
%
% 2. aseg_stats.txt
%
%    generated by running FreeSurfer's asegstats2table tool:
%
%       export SUBJECTS_DIR=/autofs/space/madrc_007/users/jab/FS4Koen
%       asegstats2table --subjects * --meas volume --segno 53 --tablefile ~/aseg_stats.txt
%
%    FORMAT:
%        Measure:volume  Right-Hippocampus       BrainSegVol     IntraCranialVol
%        080207_4TT00446 3898.0  1044570.0       1547622.2806
%        080306_4TT00468 3520.0  1063542.0       1421337.44605
%        ...
%
% 3. HippocampusSample-20091001.csv
%
%    generated by opening /home/koen/Desktop/HippocampusSample-20091001.xls in OpenOffice, and saving as
%    CSV file (text file)
%
%    FORMAT:
%
%          "subjectID" "study ID" "study date" "age" "MR ID" "FLR" "sex" "dx" "CDR" "CDRSB" "MMSE"
%          592 9136 2/21/2007 87.38 "PPG50_MD_2y" 1.24 "F" "   NC" 0 0 28
%          1340 2958 2/26/2009 83.72 "RLM012C4_MH_12m" 1.14 "F" "  MCI" 0 0 30
%          ...
%


dataMatName = 'precomputedResultsData.mat';
if exist( dataMatName, 'file' )

  disp( [ 'Reading data from pre-existing file ' dataMatName ] )
  command = [ 'load ' dataMatName ';' ];
  eval( command );

else
  
  %
  % Read contents of file partialVolumeStats.txt
  %
  
  fileName = 'partialVolumeStats.txt'
  asegStatsFileName = 'aseg_stats.txt';
  informationFileName = 'HippocampusSample-20091001.csv';
  
  disp( [ 'Reading contexts of file ' fileName ] )
  
  labels = [];
  volumes = [];
  diseaseStatuses = [];
  genders = [];
  FSHipppcampusVolumes = [];
  FSIntraCranialVols = [];
  ages = [];
  
  fid = fopen( fileName );
  while 1
    % Get the next line
    textLine = fgetl( fid );
    if ~ischar( textLine )
      break
    end
  
    % Get the first entry of this line
    locationsOfSpace = findstr( textLine, '   ' );
    key = deblank( textLine( 1 : locationsOfSpace(1) ) );
    content = deblank( textLine( locationsOfSpace(1) : end ) );
    content = [ content '   ' ];
  
  
    % If the key is "volume_in_number_of_voxels" then it is the
    % first line that defines the names of the labels
    if strcmp( key, 'volume_in_number_of_voxels' )
      % Get the labels
      locationsOfSpace = findstr( content, '   ' );
      for i = 1 : length( locationsOfSpace )-1
        label = strtrim( deblank( content( locationsOfSpace( i ) : locationsOfSpace( i+1 )-1 ) ) );
        labels = strvcat( labels, label );
      end
  
      continue
    end
  
  
    % Otherwise, get the numerical values of this field
    thisVolumes = sscanf( content, '%f' );
    volumes = [ volumes thisVolumes ];
  
    % Look up the disease status of this subject
    command = [ 'grep ' key ' ' informationFileName ];
    [ status, result ] = unix( command );
    locationOfQuotes = findstr( result, '"' );
    diseaseStatus = strtrim( deblank( result( locationOfQuotes(5)+1 : locationOfQuotes(6)-1 ) ) );
    if strcmp( diseaseStatus, 'NC' )
      diseaseStatus = 0;
    elseif strcmp( diseaseStatus, 'MCI' )
      diseaseStatus = 1;
    elseif  strcmp( diseaseStatus, 'AD' )
      diseaseStatus = 2;
    else
      diseaseStatus = 3;
    end
    diseaseStatuses = [ diseaseStatuses diseaseStatus ];
  
    % Also get gender
    gender = strtrim( deblank( result( locationOfQuotes(3)+1 : locationOfQuotes(4)-1 ) ) );
    if strcmp( gender, 'M' )
      gender = 1;
    elseif strcmp( gender, 'F' )
      gender = 0;
    else
      error( [ 'Can''t figure out gender from string ' gender ] )
    end
    genders = [ genders gender ];
  
    % Also get age
    locationOfBlanks = findstr( result, ' ' );
    age = sscanf( result( locationOfBlanks(3)+1 : locationOfBlanks(4)-1 ), '%f' );
    ages = [ ages age ];
  
  
    % Look up the FreeSurfer ICV and Hippocampal volume
    command = [ 'grep ' key ' ' asegStatsFileName ];
    [ status, result ] = unix( command );
    locationsOfSpace = findstr( textLine, ' ' );
    result = result( locationsOfSpace(1) : end );
    resultValues = sscanf( result, '%f' );
    FSHipppcampusVolume = resultValues( 1 );
    FSIntraCranialVol = resultValues( 3 );
    FSHipppcampusVolumes = [ FSHipppcampusVolumes FSHipppcampusVolume ];
    FSIntraCranialVols = [ FSIntraCranialVols FSIntraCranialVol ];
  
  end
  fclose( fid );
  
  
  
  % Also get FreeSurfer colors
  colorLookupTableFileName = '/home/koen/software/Atlas3D/FreeSurferColorLUT.txt';
  colors = [];
  for i = 1 : size( labels, 1 )
    label = deblank( labels( i, : ) );
    label = strrep( label, '2-3', '2/3' );
    label = strrep( label, '4-D', '4/D' );
  
    command = [ 'grep ' label ' ' colorLookupTableFileName ];
    [ status, result ] = unix( command );
    result = strtrim( deblank( result ) );
    locationOfLabel = findstr( result, label );
    color = sscanf( result( locationOfLabel + length( label ) : end ), '%d' );
    colors = [ colors; color' ];
  
  end
  
  disp( [ 'Saving data to file ' dataMatName ] )
  command = [ 'save ' dataMatName ' ' ...
              'labels ' ...
              'volumes ' ...
              'diseaseStatuses ' ...
              'FSHipppcampusVolumes ' ...
              'FSIntraCranialVols ' ...
              'genders ' ...
              'ages ' ...
              'colors ' ];
  eval( command )

end

if 0
  labels
  volumes
  diseaseStatuses
  FSHipppcampusVolumes
  FSIntraCranialVols
  genders
  ages
  colors
end

if 1
  % Discard bad subjects
  ind = ones( 117, 1 );
  ind( 101 ) = 0;
  ind = find( ind );

  volumes = volumes( :, ind );
  diseaseStatuses = diseaseStatuses( :, ind );
  FSHipppcampusVolumes = FSHipppcampusVolumes( :, ind );
  FSIntraCranialVols = FSIntraCranialVols( :, ind );
  genders = genders( :, ind );
  ages = ages( :, ind );

end


% Now for the real stuff
hippocampusVolumes = sum( volumes );

disp( [ 'Number of NC : ' num2str( sum( diseaseStatuses == 0 ) ) ] );
disp( [ 'Number of MCI: ' num2str( sum( diseaseStatuses == 1 ) ) ] );
disp( [ 'Number of AD : ' num2str( sum( diseaseStatuses == 2 ) ) ] );


figure
set( gcf, 'color', 'w' )
p = plot( FSHipppcampusVolumes ./ FSIntraCranialVols, ...
          hippocampusVolumes ./ FSIntraCranialVols, ...
          'linestyle', 'none', 'marker', 'o' );
xlim = get( gca, 'xlim' );
ylim = get( gca, 'ylim' );
lim = [ min( xlim(1), ylim(1) )  max( xlim(2), ylim(2) ) ];
set( gca, 'xlim', lim, 'ylim', lim )
l = line( [ lim(1) lim(2) ]', [ lim(1) lim(2) ]', 'color', 'r', 'linestyle', '-' )
grid
xlabel( 'FreeSurfer total hippo' )
ylabel( 'New total hippo' )


% Something different in FS segmentations for very small hippos - we're oversegmenting or
% FS is undersegmenting. Find out the 5 smalles FS segmentations, and compare volumes
if 0
  [ dummy, indices ] = sort( FSHipppcampusVolumes ./ FSIntraCranialVols );
  for subjectNumber = indices( [ 1 : 10 ] )
    disp( [ 'subject number ' num2str( subjectNumber ) ] )
    disp( [ '   Oversegmentation of total hippo volume compared to FS: ' ...
            num2str( ( hippocampusVolumes( subjectNumber ) - FSHipppcampusVolumes( subjectNumber ) ) / FSHipppcampusVolumes( subjectNumber ) * 100 ) '%' ] )
    disp( [ '   DiseaseStatus: ' num2str( diseaseStatuses( subjectNumber ) ) ] )
  end
elseif 0
  
  relativeVolumeDifferences = ( hippocampusVolumes - FSHipppcampusVolumes ) ./ FSHipppcampusVolumes * 100;

  [ dummy, indices ] = sort( abs( relativeVolumeDifferences ) );
  for subjectNumber = indices( [ end : -1 : end-9 ] )
    disp( [ 'subject number ' num2str( subjectNumber ) ] )
    disp( [ '   Oversegmentation of total hippo volume compared to FS: ' ...
            num2str( relativeVolumeDifferences( subjectNumber ) ) '%' ] )
    disp( [ '   DiseaseStatus: ' num2str( diseaseStatuses( subjectNumber ) ) ] )
  end

  % Let't test removing these subjects
  indicesToUse = [ 1 : size( volumes, 2 ) ];
  for indexToRemove = indices( [ end : -1 : end-9 ] )
    indicesToUse = indicesToUse( find( indicesToUse ~= indexToRemove ) );
  end
  volumes = volumes( :, indicesToUse );
  hippocampusVolumes = hippocampusVolumes( :, indicesToUse );
  diseaseStatuses = diseaseStatuses( :, indicesToUse );
  FSHipppcampusVolumes = FSHipppcampusVolumes( :, indicesToUse );
  FSIntraCranialVols = FSIntraCranialVols( :, indicesToUse );
  genders = genders( :, indicesToUse );
  ages = ages( :, indicesToUse );
  relativeVolumeDifferences = relativeVolumeDifferences( :, indicesToUse );

end



for compareStatistics = 0 : 3
  makeVolumePlot( FSHipppcampusVolumes ./ FSIntraCranialVols, ...
                  'FreeSurfer total hippo', diseaseStatuses, [ 0.2 0.2 0.2 ], compareStatistics );
  set( gcf, 'name', 'FreeSurfer results' );
end

for compareStatistics = 0 : 3
  makeVolumePlot( hippocampusVolumes ./ FSIntraCranialVols, ...
                      'Total hippo', diseaseStatuses, [ 0.2 0.2 0.2 ], compareStatistics  );
  set( gcf, 'name', 'New results' );
end

if 0
  for compareStatistics = 0 : 3
    hippocampusVolumesWithoutFissure = sum( volumes( 1 : end-1, : ) );
    makeVolumePlot( hippocampusVolumesWithoutFissure ./ FSIntraCranialVols, ...
                        'Total hippo without fissure', diseaseStatuses, [ 0.2 0.2 0.2 ], compareStatistics  );
    set( gcf, 'name', 'New results without fissure' );
  end
end

for compareStatistics = 0 : 3
  makeVolumePlot( volumes ./ repmat( FSIntraCranialVols, [ size( labels, 1 ) 1 ] ), ...
                      labels, diseaseStatuses, colors, compareStatistics );
  set( gcf, 'name', 'Subfield volumes (normalized for head size)' );
end


%  f = makeVolumePlot( volumes ./ repmat( hippocampusVolumes, [ size( labels, 1 ) 1 ] ), ...
%                      labels, diseaseStatuses, colors );
%  title( 'Subfield volumes (normalized for hippocampal volumes)' );
%  
%  f = makeVolumePlot( volumes ./ repmat( hippocampusVolumesWithoutFissure, [ size( labels, 1 ) 1 ] ), ...
%                      labels, diseaseStatuses, colors );
%  title( 'Subfield volumes (normalized for hippocampal volumes without fissure)' );


if 0
% Also show ages and genders
f = makeVolumePlot( ages, ...
                   'ages', diseaseStatuses );
title( 'Age distributions' );
f = makeVolumePlot( genders, ...
                   'genders', diseaseStatuses );
title( 'Gender distributions' );
end


if 0
  % Let's try to remove effect of age and gender and head size
  correctedVolumes = [];
  for labelNumber = 1 : size( labels, 1 )
    %A = [ genders' ages' ];
    A = [ genders' ages' FSIntraCranialVols' ];
    lsFit = A * ( ( A' * A ) \ ( A' * ( volumes( labelNumber, : ) )' ) );
    correctedVolumes = [ correctedVolumes; volumes( labelNumber, : ) - lsFit' ];
  end

  volumes = correctedVolumes;


  hippocampusVolumes = sum( volumes );

  f = makeVolumePlot( FSHipppcampusVolumes, ...
                    'FreeSurfer total hippo', diseaseStatuses );
  title( 'FreeSurfer results' );
  
  f = makeVolumePlot( hippocampusVolumes, ...
                      'Total hippo', diseaseStatuses );
  title( 'New results' );
  
  hippocampusVolumesWithoutFissure = sum( volumes( 1 : end-1, : ) );
  f = makeVolumePlot( hippocampusVolumesWithoutFissure, ...
                      'Total hippo without fissure', diseaseStatuses );
  title( 'New results without fissure' );
  
  f = makeVolumePlot( volumes, ...
                      labels, diseaseStatuses, colors );
  title( 'Subfield volumes' );
  
end


if false
  % Let's have a hack: only use first 18 controls
  indicesToKeep = find( diseaseStatuses == 0 );
  indicesToKeep = indicesToKeep( 1 : 18 );
  indicesToKeep = [ indicesToKeep find( diseaseStatuses ~= 0 ) ];

  volumes = volumes( :, indicesToKeep );
  hippocampusVolumes = hippocampusVolumes( :, indicesToKeep );
  diseaseStatuses = diseaseStatuses( :, indicesToKeep );
  FSHipppcampusVolumes = FSHipppcampusVolumes( :, indicesToKeep );
  FSIntraCranialVols = FSIntraCranialVols( :, indicesToKeep );
end


% Let's try something new: Fisher's Discriminant Analysis on MCI vs. AD volume
for i = 1 : 3
  if ( i == 1 )
    disp( 'NC vs. MCI' )
    diseaseStatus1 = 0;
    diseaseStatus2 = 1;
  elseif ( i == 2 )
    disp( 'NC vs. AD' )
    diseaseStatus1 = 0;
    diseaseStatus2 = 2;
  elseif  ( i == 3 )
    disp( 'MCI vs. AD' )
    diseaseStatus1 = 1;
    diseaseStatus2 = 2;
  else
    error( 'hmm..' );
  end


  normalizedVolumes = volumes ./ repmat( FSIntraCranialVols, [ size( labels, 1 ) 1 ] );
  x1s = normalizedVolumes( :, find( diseaseStatuses == diseaseStatus1 ) ); % MCI
  x2s = normalizedVolumes( :, find( diseaseStatuses == diseaseStatus2 ) ); % AD

  % Normalize the data
  numberOfFeatures = size( x1s, 1 );
  for featureNumber = 1 : numberOfFeatures
    data = [ x1s( featureNumber, : ) x2s( featureNumber, : ) ];
    mean = sum( data ) / length( data );
    variance = sum( ( data - mean ).^2 ) / length( data );
    x1s( featureNumber, : ) = ( x1s( featureNumber, : ) - mean ) / sqrt( variance );
    x2s( featureNumber, : ) = ( x2s( featureNumber, : ) - mean ) / sqrt( variance );
  end


  % Bishop's book p. 186-189
  N1 = size( x1s, 2 );
  N2 = size( x2s, 2 );
  m1 = sum( x1s, 2 ) / N1;
  m2 = sum( x2s, 2 ) / N2;
  Sw = ( x1s - repmat( m1, [ 1 N1 ] ) ) * ( x1s - repmat( m1, [ 1 N1 ] ) )' + ...
      ( x2s - repmat( m2, [ 1 N2 ] ) ) * ( x2s - repmat( m2, [ 1 N2 ] ) )';
  w = Sw \ ( m2 - m1 );
  w = w / sqrt( sum( w.^2 ) );

  disp( '   optimal weights:' )
  for i = 1 : numberOfFeatures
    disp( [ '        ' deblank( labels( i, : ) ) ': ' num2str( w( i ) ) ] )
  end


  % Compare to simply looking at one feature at a time
  ws = [ eye( numberOfFeatures, numberOfFeatures ) w ];
  titles = strvcat( labels, 'best projection' ); 
  
  for i = 1 : size( ws, 2 )
    % 
    w = ws( :, i );
  
    % Projections
    p1s = w' * x1s;
    p2s = w' * x2s;
    pm1 = w' * m1; % projection of m1
    pm2 = w' * m2; % projection of m2
    middle = ( pm1 + pm2 ) / 2;
    p1s = p1s - middle;
    p2s = p2s - middle;
  
    if 0
      % Instead of just setting threshold in the middle (i.e., at 0 in the current
      % normalized data), try to find the best value
    end
  
    figure
    if 0
      [ n1 x1 ] = hist( p1s', 10 );
      bar( x1, n1 );
      hold on
      [ n2 x2 ] = hist( p2s', 10 );
      bar( x2, n2, 'r' );
    else
      line( p1s', zeros( N1, 1 ) - .3, 'marker', 'o', 'linestyle', 'none', 'color', 'b' );
      hold on
      line( p2s', zeros( N2, 1 ) + .3, 'marker', 'o', 'linestyle', 'none', 'color', 'r' );
      set( gca, 'ylim', [ -1 1 ] );
      trainingCorrectClassificationRate = ( sum( p1s < 0 ) + sum( p2s > 0 ) ) / ( N1 + N2 );
      trainingCorrectClassificationRate = max( trainingCorrectClassificationRate, 1 - trainingCorrectClassificationRate );
      title( [ deblank( titles( i, : ) ) ' (' num2str( trainingCorrectClassificationRate * 100 ) '%)' ] )
    end
  end
  
  
  
  % Let's do a proper leave-one-out validation
  useSimpleThreshold = true;
  
  xs = [ x1s x2s ];
  classifications = [ zeros( 1, size( x1s, 2 ) ) ones( 1, size( x2s, 2 ) ) ];
  numberOfSubjects = length( classifications );
  
  numberOfClassificationErrors = 0;
  for subjectNumber = 1 : numberOfSubjects
    useSubjects = ones( 1, numberOfSubjects );
    useSubjects( subjectNumber ) = 0;
  
    trainingXs = xs( :, find( useSubjects ) );
    trainingClassifications = classifications( :, find( useSubjects ) );
  
    x1s = trainingXs( :, find( trainingClassifications == 0 ) ); % MCI
    x2s = trainingXs( :, find( trainingClassifications == 1 ) ); % AD
  
    % Bishop's book p. 186-189
    N1 = size( x1s, 2 );
    N2 = size( x2s, 2 );
    m1 = sum( x1s, 2 ) / N1;
    m2 = sum( x2s, 2 ) / N2;
    Sw = ( x1s - repmat( m1, [ 1 N1 ] ) ) * ( x1s - repmat( m1, [ 1 N1 ] ) )' + ...
        ( x2s - repmat( m2, [ 1 N2 ] ) ) * ( x2s - repmat( m2, [ 1 N2 ] ) )';
    w = Sw \ ( m2 - m1 );
    w = w / sqrt( sum( w.^2 ) );
  
  
    % Check if we would classify it correctly
    testingX = xs( :, subjectNumber );
    testingClassification = classifications( :, subjectNumber );
    if useSimpleThreshold
      % Use middle between means as the threshold to classify
      pm1 = w' * m1; % projection of m1
      pm2 = w' * m2; % projection of m2
      middle = ( pm1 + pm2 ) / 2;
      predictedClassification = ( ( w' * testingX ) > middle );
    else
      % Use proper Gaussian mixture model to determine the threshold
      px1s = w' * x1s;
      px2s = w' * x2s;
      pm1 = sum( px1s ) / N1;
      pm2 = sum( px2s ) / N2;
      pv1 = sum( ( px1s - pm1 ).^2 ) / N1;
      pv2 = sum( ( px2s - pm2 ).^2 ) / N2;
      propToPosterior1 = 1 / sqrt( 2 * pi * pv1 ) * exp( -( w' * testingX - pm1 )^2 / 2 / pv1 ) * N1;
      propToPosterior2 = 1 / sqrt( 2 * pi * pv2 ) * exp( -( w' * testingX - pm2 )^2 / 2 / pv2 ) * N2;
      predictedClassification = ( propToPosterior2 > propToPosterior1 );
    end
  
  
    if ( testingClassification ~= predictedClassification )
      numberOfClassificationErrors = numberOfClassificationErrors + 1;
    end
  
  end % End loop over all subjects
  
  testingCorrectClassificationRate = ( numberOfSubjects - numberOfClassificationErrors ) ...
                                    / numberOfSubjects;
  disp( [ '   testingCorrectClassificationRate subfields: ' num2str( testingCorrectClassificationRate * 100 ) ] )
  
  
  % Compare that to FS results
  tmp = FSHipppcampusVolumes ./ FSIntraCranialVols;
  x1s = tmp( find( diseaseStatuses == diseaseStatus1 ) );
  x2s = tmp( find( diseaseStatuses == diseaseStatus2 ) );
  xs = [ x1s x2s ];
  classifications = [ zeros( 1, size( x1s, 2 ) ) ones( 1, size( x2s, 2 ) ) ];
  numberOfSubjects = length( classifications );
  numberOfClassificationErrors = 0;
  for subjectNumber = 1 : numberOfSubjects
    useSubjects = ones( 1, numberOfSubjects );
    useSubjects( subjectNumber ) = 0;
  
    trainingXs = xs( :, find( useSubjects ) );
    trainingClassifications = classifications( :, find( useSubjects ) );
  
    x1s = trainingXs( :, find( trainingClassifications == 0 ) ); % MCI
    x2s = trainingXs( :, find( trainingClassifications == 1 ) ); % AD
  
    % Bishop's book p. 186-189
    N1 = size( x1s, 2 );
    N2 = size( x2s, 2 );
    m1 = sum( x1s, 2 ) / N1;
    m2 = sum( x2s, 2 ) / N2;
    Sw = ( x1s - repmat( m1, [ 1 N1 ] ) ) * ( x1s - repmat( m1, [ 1 N1 ] ) )' + ...
        ( x2s - repmat( m2, [ 1 N2 ] ) ) * ( x2s - repmat( m2, [ 1 N2 ] ) )';
    w = Sw \ ( m2 - m1 );
    w = w / sqrt( sum( w.^2 ) );
  
  
    % Check if we would classify it correctly
    pm1 = w' * m1; % projection of m1
    pm2 = w' * m2; % projection of m2
    middle = ( pm1 + pm2 ) / 2;
    testingX = xs( :, subjectNumber );
    testingClassification = classifications( :, subjectNumber );
  
    predictedClassification = ( ( w' * testingX ) > middle );
  
    if ( testingClassification ~= predictedClassification )
      numberOfClassificationErrors = numberOfClassificationErrors + 1;
    end
  
  end % End loop over all subjects
  
  testingCorrectClassificationRate = ( numberOfSubjects - numberOfClassificationErrors ) ...
                                    / numberOfSubjects;
  disp( [ '   testingCorrectClassificationRate FreeSurfer: ' num2str( testingCorrectClassificationRate * 100 ) ] )
  
  
  
  % Compare that to global hippo volume results
  tmp = hippocampusVolumes ./ FSIntraCranialVols;
  x1s = tmp( find( diseaseStatuses == diseaseStatus1 ) );
  x2s = tmp( find( diseaseStatuses == diseaseStatus2 ) );
  xs = [ x1s x2s ];
  classifications = [ zeros( 1, size( x1s, 2 ) ) ones( 1, size( x2s, 2 ) ) ];
  numberOfSubjects = length( classifications );
  numberOfClassificationErrors = 0;
  for subjectNumber = 1 : numberOfSubjects
    useSubjects = ones( 1, numberOfSubjects );
    useSubjects( subjectNumber ) = 0;
  
    trainingXs = xs( :, find( useSubjects ) );
    trainingClassifications = classifications( :, find( useSubjects ) );
  
    x1s = trainingXs( :, find( trainingClassifications == 0 ) ); % MCI
    x2s = trainingXs( :, find( trainingClassifications == 1 ) ); % AD
  
    % Bishop's book p. 186-189
    N1 = size( x1s, 2 );
    N2 = size( x2s, 2 );
    m1 = sum( x1s, 2 ) / N1;
    m2 = sum( x2s, 2 ) / N2;
    Sw = ( x1s - repmat( m1, [ 1 N1 ] ) ) * ( x1s - repmat( m1, [ 1 N1 ] ) )' + ...
        ( x2s - repmat( m2, [ 1 N2 ] ) ) * ( x2s - repmat( m2, [ 1 N2 ] ) )';
    w = Sw \ ( m2 - m1 );
    w = w / sqrt( sum( w.^2 ) );
  
  
    % Check if we would classify it correctly
    pm1 = w' * m1; % projection of m1
    pm2 = w' * m2; % projection of m2
    middle = ( pm1 + pm2 ) / 2;
    testingX = xs( :, subjectNumber );
    testingClassification = classifications( :, subjectNumber );
  
    predictedClassification = ( ( w' * testingX ) > middle );
  
    if ( testingClassification ~= predictedClassification )
      numberOfClassificationErrors = numberOfClassificationErrors + 1;
    end
  
  end % End loop over all subjects
  
  testingCorrectClassificationRate = ( numberOfSubjects - numberOfClassificationErrors ) ...
                                    / numberOfSubjects;
  disp( [ '   testingCorrectClassificationRate new hippo volume: ' num2str( testingCorrectClassificationRate * 100 ) ] )
  

end % End loop over class combinations to classify

  