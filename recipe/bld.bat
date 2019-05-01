set "INCLUDE=%LIBRARY_PREFIX%\include\cairo;%INCLUDE%"
%PYTHON% -m pip install --no-deps --ignore-installed -v .
if errorlevel 1 exit 1
