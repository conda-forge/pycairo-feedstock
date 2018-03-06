set "INCLUDE=%LIBRARY_PREFIX%\include\cairo;%INCLUDE%"
python setup.py install
if errorlevel 1 exit 1
