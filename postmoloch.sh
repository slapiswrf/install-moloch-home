#!/bin/bash                                                                                                                                                            
                                                                                                                                                                       
# Post-traitement MHF → GRIB2, nettoyage complet des valeurs invalides                                                                                                 
                                                                                                                                                                       
OUT_DIR="post_results"                                                                                                                                                 
                                                                                                                                                                       
mkdir -p "$OUT_DIR"                                                                                                                                                    
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
for atm_file in moloch_atm_*.mhf; do                                                                                                                                   
                                                                                                                                                                       
    num=$(echo "$atm_file" | sed -E 's/.*_([0-9]+)\.mhf/\1/')                                                                                                          
                                                                                                                                                                       
    soil_file="moloch_soil_${num}.mhf"                                                                                                                                 
                                                                                                                                                                       
                                                                                                                                                                       
    if [ ! -f "$soil_file" ]; then                                                                                                                                     
                                                                                                                                                                       
        echo "⚠ Fichier SOIL manquant pour $atm_file, passage au suivant."                                                                                             
                                                                                                                                                                       
        continue                                                                                                                                                       
                                                                                                                                                                       
    fi                                                                                                                                                                 
                                                                                                                                                                       
                                                                                                                                                                       
    echo "----------------------------------------"                                                                                                                    
                                                                                                                                                                       
    echo "Traitement MHF n°$num :"                                                                                                                                     
                                                                                                                                                                       
    echo "ATM : $atm_file"                                                                                                                                             
                                                                                                                                                                       
    echo "SOIL: $soil_file"                                                                                                                                            
                                                                                                                                                                       
    echo "----------------------------------------"                                                                                                                    
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    # Créer les liens pour postmoloch                                                                                                                                  
                                                                                                                                                                       
    ln -svf $atm_file moloch_atm.mhf                                                                                                                                   

    ln -svf $soil_file moloch_soil.mhf                                                                                                                                 
                                                                                                                                                                       
                                                                                                                                                                       
    # Lancer postmoloch                                                                                                                                                
                                                                                                                                                                       
    ./postmoloch                                                                                                                                                       
                                                                                                                                                                       
    wait                                                                                                                                                               
                                                                                                                                                                       
    sleep 1                                                                                                                                                            
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
   # docer les GRIB2 générés                                                                                                                                           
                                                                                                                                                                       
    grib_files=$(ls moloch_*.grib2 2>/dev/null)                                                                                                                        
                                                                                                                                                                       
    for gf in $grib_files; do                                                                                                                                          
                                                                                                                                                                       
    mv "$gf" "$OUT_DIR/${num}_$gf"                                                                                                                                     
                                                                                                                                                                       
done                                                                                                                                                                   
                                                                                                                                                                       
                                                                                                                                                                       
    echo "Fichiers GRIB2 déplacés dans $OUT_DIR."                                                                                                                      
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    # Supprimer les temporaires                                                                                                                                        
                                                                                                                                                                       
    rm -f tmp_atm.mhf tmp_soil.mhf                                                                                                                                     
                                                                                                                                                                       
done                                                                                                                                                                   
                                                                                                                                                                       
                                                                                                                                                                       
echo "----------------------------------------"                                                                                                                        
                                                                                                                                                                       
echo "Traitement terminé. Tous les GRIB2 sont dans : $OUT_DIR" 
