#script de post-traitement Moloch : conversion SHF → GRIB2                                                                                                             
                                                                                                                                                                       
# -------------------------------------------------------------------                                                                                                  
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
# Répertoire ECCODES                                                                                                                                                   
                                                                                                                                                                       
export DIR_GRIB_LIB=/cluster/sources/eccodes/2.14.1/eccodes-2.14.1-Source                                                                                              
                                                                                                                                                                       
                                                                                                                                                                       
CURDIR=`pwd`                                                                                                                                                           
# Créer le répertoire et le lien vers les samples ECCODES si nécessaire                                                                                                
                                                                                                                                                                       
mkdir -p "$DIR_GRIB_LIB/share/eccodes"                                                                                                                                 
                                                                                                                                                                       
if [ ! -e "$CURDIR/samples" ]; then                                                                                                                                    
                                                                                                                                                                       
    ln -s "$DIR_GRIB_LIB/samples" .                                                                                                                                    
                                                                                                                                                                       
fi                                                                                                                                                                     
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
# Répertoire de sortie pour les GRIB2                                                                                                                                  
                                                                                                                                                                       
OUT_DIR="post_results"                                                                                                                                                 
                                                                                                                                                                       
mkdir -p "$OUT_DIR"                                                                                                                                                    
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
# Boucle sur tous les fichiers moloch_*.shf                                                                                                                            
                                                                                                                                                                       
for shf_file in moloch_*.shf; do                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    # Nom de base du fichier                                                                                                                                           
                                                                                                                                                                       
    base_name=$(basename "$shf_file" .shf)                                                                                                                             
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    echo "----------------------------------------"                                                                                                                    
                                                                                                                                                                       
    echo "Traitement du fichier : $shf_file"                                                                                                                           
                                                                                                                                                                       
    echo "----------------------------------------"                                                                                                                    
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    # Créer un lien symbolique vers input.shf pour le convertisseur                                                                                                    
                                                                                                                                                                       
    ln -sf "$shf_file" input.shf                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    # Lancer la conversion SHF → GRIB2                                                                                                                                 
                                                                                                                                                                       
    ./convert_shf_to_grib2                                                                                                                                             
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
    # Vérifier si des fichiers GRIB2 ont été créés                                                                                                                     
                                                                                                                                                                       
    grib_files=$(ls moloch_*.grib2 2>/dev/null)                                                                                                                        
                                                                                                                                                                       
    if [ -n "$grib_files" ]; then                                                                                                                                      
                                                                                                                                                                       
        for gf in $grib_files; do                                                                                                                                      
                                                                                                                                                                       
            mv "$gf" "$OUT_DIR/${base_name}_$gf"                                                                                                                       
                                                                                                                                                                       
        done                                                                                                                                                           
                                                                                                                                                                       
        echo "Fichiers GRIB2 déplacés dans $OUT_DIR."                                                                                                                  
                                                                                                                                                                       
    else                                                                                                                                                               
                                                                                                                                                                       
        echo "⚠ Aucun fichier GRIB2 créé pour $shf_file"                                                                                                               
                                                                                                                                                                       
    fi                                                                                                                                                                 
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
done                                                                                                                                                                   
                                                                                                                                                                       
                                                                                                                                                                       
                                                                                                                                                                       
echo "----------------------------------------"                                                                                                                        
                                                                                                                                                                       
echo "Traitement terminé. Tous les GRIB2 sont dans : $OUT_DIR"
