#!/bin/bash                                                                                                            
                                                                                                                        
 ##############################################################################                                         
 # Build the entire solution using Wine for Windows-specific projects         #                                         
 #                                                                            #                                         
 # This script builds the solution on Linux using Wine for Windows projects.  #                                         
 # It assumes Wine and winetricks are installed and configured properly.      #                                         
 ##############################################################################                                         
                                                                                                                        
 export configuration="Release"                                                                                         
 export verbosity="minimal"                                                                                             
 export output="bin"                                                                                                    
 export solutionBase="OpenKh.Linux"                                                                                     
 export solution="$solutionBase.sln"                                                                                    
 export WINEPREFIX="$HOME/.local/share/wineprefixes/openkh"                                                                       
                                                                                                                        
function run_in_wineprefix() {
    WINEPREFIX="$WINEPREFIX" wine "$@"
}

function setup_wine_prefix() {                                                                                                  
    echo "Setting up Wine prefix..."                                                                                   
    run_in_wineprefix winetricks --unattended vcrun20222 dotnet48 corefonts                                                                                        
}
                                                                                                                        
 function teardown_wine_prefix() {                                                                                               
     echo "Tearing down Wine prefix..."                  
     killall wineserver                                                               
     rm -rf "$WINEPREFIX"                                                                                               
 }                                                                                                                      
                                                                                                 
 # Update submodules                                                                                                    
 git submodule update --init --recursive --depth 1                                                                      
 if [ $? -ne 0 ]; then                                                                                                  
     exit 1                                                                                                             
 fi                                                                                                                     
                                                                                                                        
 # Create solution for Linux and macOS                                                                                  
 dotnet new sln -n $solutionBase --force                                                                                
 if [ $? -ne 0 ]; then                                                                                                  
     exit 1                                                                                                             
 fi                                                                                                                     
                                                                                                                        
 # Add only command line tools to the new solution                                                                      
 for project in ./OpenKh.Command.*/*.csproj; do                                                                         
     dotnet sln $solution add "$project"                                                                                
 done                                                                                                                   
 for project in ./OpenKh.Game*/*.csproj; do                                                                             
     dotnet sln $solution add "$project"                                                                                
 done                                                                                                                   
                                                                                                                        
 # Restore NuGet packages                                                                                               
 dotnet restore $solution                                                                                               
 if [ $? -ne 0 ]; then                                                                                                  
     rm $solution                                                                                                       
     exit 1                                                                                                             
 fi                                                                                                                     
                                                                                                                        
 # Run tests                                                                                                            
 dotnet test $solution --configuration $configuration --verbosity $verbosity                                            
 if [ $? -ne 0 ]; then                                                                                                  
     rm $solution                                                                                                       
     exit 1                                                                                                             
 fi                                                                                                                     
                                                                                                                        
 # Publish solution                                                                                                     
 dotnet publish $solution --configuration $configuration --verbosity $verbosity --framework net6.0 --output $output     
 /p:DebugType=None /p:DebugSymbols=false                                                                                
                                                                                                                        
 # Set up Wine prefix                                                                                                   
 setup_wine_prefix                                                                                                      
                                                                                                                        
 # Use Wine to build Windows-specific projects                                                                          
 for project in ./OpenKh.Tools.*/*.csproj; do                                                                           
     WINEPREFIX="$WINEPREFIX" wine dotnet build "$project" --configuration $configuration --output $output              
 done                                                                                                                   
                                                                                                                        
 # Tear down Wine prefix                                                                                                
 teardown_wine_prefix                                                                                                   
                                                                                                                        
 rm $solution                                                                                                           
                                                                                                                        
 # Print some potentially useful info                                                                                   
 echo "It is very recommended to append to your '~/.profile' file the path of"                                          
 echo "OpenKH binaries and their alias to run them from any folder. You only"                                           
 echo "need to do it once per user."                                                                                    
 echo "To do so, please execute the following commands:"                                                                
                                                                                                                        
 awk '{ sub("\r$", ""); print }' ./openkh_alias > ./bin/openkh_alias                                                    
 chmod +x ./bin/OpenKh.Command.*                                                                                        
 export OPENKH_BIN="$(realpath ./bin)"                                                                                  
 echo "echo 'export OPENKH_BIN=\"$OPENKH_BIN\"' >> ~/.profile"                                                          
 echo "echo 'export PATH=\$PATH:\$OPENKH_BIN' >> ~/.profile"                                                            
 echo "echo 'source \$OPENKH_BIN/openkh_alias' >> ~/.profile"    
