#!/bin/bash

#debug
#set -xv

#Le script doit être situé dans le répertoire $HOME

#variables
journal="$HOME/synjournal.log"
ArbreA="$HOME/synchroniseur/A"
ArbreB="$HOME/synchroniseur/B"
#journal temporaire
touch $HOME/journalTemp.txt
journalTemp="$HOME/journalTemp.txt"
#journal des conflits
touch $HOME/listcft.txt

#Initialisation de du booléen conflit
conflit=0;

#fonction du synchronisation sur le journal
function Jsync {
	
#$fichierA sera celui inscrit dans le journal et servant de référence
journalA_date=$fichierA_date
journalA_heure=$fichierA_heure
journalA_type=$fichierA_type
journalA_droits=$fichierA_droits
journalA_taille=$fichierA_taille
	
	
#FichierA
#affichage de la date de synchronisation
echo "Date de synchronisation : `date`" >> $journalTemp
#affichage du chemin absolu du fichier dans le journal
echo "Chemin absolu : $fichierA" >> $journalTemp
#Affichage du type de fichier
echo "Type: $journalA_type" >> $journalTemp
#affichage des droits, taille et date d'accès du fichier
echo "Infos:" >> $journal
echo "Date: $journalA_date" >> $journalTemp
echo "Heure: $journalA_heure" >> $journalTemp
echo "Droits: $journalA_droits" >> $journalTemp
echo "Taille: $journalA_taille" >> $journalTemp
echo "######################################" >> $journalTemp
	
}

function lstcft {
echo "conflit : $conflit"
if [ $conflit = 1 ]
then
	echo "Des conflits ont été détectés, voici la liste des fichiers concernés"
	cat $HOME/listcft.txt
	echo "Choisissez les mesures à prendre:"
	echo "1) Afficher les différences entre les fichiers?"
	echo "2) Supprimer les fichiers concernés?"
	echo "3) ne rien faire"
	read choix
	case $choix in
		1) echo ""
		   diff $fichierA $fichierB -s
		   lstcft
		   ;;
		2) echo ""
			#vérifier si le fichier n'est pas un répertoire, puis -> rm -Rf monrepertoire
		   echo "La suppression des fichiers va commencer"
			while read fich; do
				rm $fich
			done <$HOME/listcft.txt
		   ;;
		3) echo ""
		   echo "Aucune modification ne sera apportée aux fichiers"
		   exit 1
		   ;;
		*) echo "Désolé, veuillez choisir les options 1, 2 ou 3"
           	   lstcft
           ;;
	esac

fi
}


#fonction du synchroniseur
function prmain {

echo "Affichage des fichiers de l'arbre A"
for fichierA in $ArbreA/*
do
  if [ -f "$fichierA" ]
  then
  	basename $fichierA
  fi
  if [ -d "$fichierA" ]
  then
  	echo "$fichierA est un répertoire"
  fi

echo "Affichage des fichiers de l'arbre B"
for fichierB in $ArbreB/*
do
	if [ -f "$fichierB" ]
  	then
  		basename $fichierB
  	fi
  	if [ -d "$fichierB" ]
  	then
  		echo "$fichierB est un répertoire"
  	fi

	echo "fichierA = $fichierA"
	echo "fichierB= $fichierB"

	#Si $fichierA a le même nom que $fichierB
	if [ `basename "$fichierA"` = `basename "$fichierB"` ]
	then
		echo "fichierA apres boucle = $fichierA"
		echo "fichierB apres boucle= $fichierB"
		
		#Vérication de la différence de contenu entre deux fichiers
		diff=`diff $fichierA $fichierB`
		diff=`echo $?`

		#Affichage du nom du fichier dans la variable (sans le chemin absolu)
		fichierA_nom=`basename $fichierA`
		fichierB_nom=`basename $fichierB`
	
		#Affichage de la date (JJMMAA)
		fichierA_date=`stat $fichierA | grep Modif | cut -c11-20`
		fichierB_date=`stat $fichierB |grep Modif | cut -c11-20`

		#Affichage de l'heure (H:M:S)
		#Utiliser c22-29 pour l'heure pour enlever les milisecondes (c22-39), si la gestion des milisecondes devient trop compliquée
		fichierA_heure=`stat $fichierA | grep Modif | cut -c22-29`
		fichierB_heure=`stat $fichierB | grep Modif | cut -c22-29`
	
		#Affichage du type du fichier
		#mode -b "brief" pour empêcher l'erreur "trop d'arguments en paramètres, tr -d pour supprimer les espaces et ainsi éviter la casse"
		fichierA_type=`file -b $fichierA | tr -d ' '`
		fichierB_type=`file -b $fichierB | tr -d ' '`

		#Affichage des droits du fichier sous forme "rwx rwx rwx"
		fichierA_droits=`stat $fichierA | grep Accès | cut -c16-26 | grep /`
		fichierB_droits=`stat $fichierB | grep Accès | cut -c16-26 | grep /`

		#Affichage des droits du fichier sous forme "777"
		fichierA_droits_N=`stat $fichierA | grep Accès | cut -c12-15 | grep '^0'`
		fichierB_droits_N=`stat $fichierB | grep Accès | cut -c12-15 | grep '^0'`

		#Affichage de la taille du fichier
		fichierA_taille=`stat $fichierA | grep Taille | cut -c14-24`
		fichierB_taille=`stat $fichierB | grep Taille | cut -c14-24`

		#S'ils ont une entrée dans le journal
		position=`grep $fichierA $journal -c`
		echo $position
			if [ "$position" -eq 1 ]
			then

			
		   	 #S'ils ont les mêmes métadonnées, même contenu
			

			#Synchronisation réussie, on crée une entrée -> JSync
			#Si les deux fichiers sont bien des fichiers, et qu'ils ont le même contenu ainsi que les même métadonnées, alors la synchronisation est réussie

			if [ -f "$fichierA" -a -f "$fichierB" ] && [ "$diff" = 0 ] && [ "$fichierA_date" = "$fichierB_date" ] && [ "$fichierA_heure" = "$fichierB_heure" ] && [ "$fichierA_type" = "$fichierB_type" ] && [ "$fichierA_droits" = "$fichierB_droits" ] && [ "$fichierA_taille" = "$fichierB_taille" ] && [ "$fichierA_nom" = "$fichierB_nom" ]
			then
				echo "La date de modification, les droits, le type et la taille de $fichierA correspondent à celles de $fichierB, la synchronisation est réussie"
				Jsync
			
			fi
    #Sinon
			#Si l'un est un fichier et l'autre un répertoire

			#Si $fichierA est un fichier et $fichierB un répertoire, il y a conflit.
			if [ -d "$fichierA" -a -f "$fichierB" ] || [ -f "$fichierA" -a -d "$fichierB" ]
			then
				echo "Conflit entre $fichierA et $fichierB"
				let conflit++
				
				if [ -d "$fichierA" -a -f "$fichierB" ]
				then
					echo "$fichierA est un répertoire et $fichierB un fichier"
				fi
				if [ -f "$fichierA" -a -d "$fichierB" ]
				then
					echo "$fichierB est un répertoire et $fichierA un fichier"
				fi
			
			basename $fichierA >> listcft.txt
			basename $fichierB >> listcft.txt
			
			fi
			#Si ce sont tous les deux des répertoires
			#fichierA et fichierB étant des répertoires, on descend dans l'arborescense
			if [ -d "$fichierA" ] && [ -d "$fichierB" ]
			then
				echo "$fichierA et $fichierB sont des répertoires"
				ArbreA="$HOME/synchroniseur/A/$fichierA"
				ArbreA="$HOME/synchroniseur/A/$fichierB"
				prmain
		
			fi
                #Si pas les mêmes métadonnées
                    #On prend les métadonnées les plus récentes
                    #Synchronisation réussie, on crée une entrée -> JSync

		#Si les fichiers sont bien des fichiers, mais que les métadonnées de B et A différents par rapport au journal ou inversement, alors on copie les métadonnées du fichier qui est en accord avec le journal sur le fichier qui ne l'est pas

	#De plus, si le contenu d'un fichier diffère de celui qui est conforme au journal, alors le contenu de celui conforme est copié sur celui non conforme
	
		if [ -f "$fichierA" ] && [ -f "$fichierB" ]
		then
			if [ "$position" = 1 ] && [ "$diff" = 0 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierA_date" != "$journalA_date" ] || [ "$fichierA_heure" != "$journalA_heure" ] || [ "$fichierA_type" != "$journalA_type" ] || [ "$fichierA_droits" != "$journalA_droits" ] || [ "$fichierA_taille" != "$journalA_taille" ] && [ "$fichierB_date" = "$journalA_date" ] && [ "$fichierB_heure" = "$journalA_heure" ] && [ "$fichieB_type" = "$journalA_type" ] && [ "$fichierB_droits" = "$journalA_droits" ] && [ "$fichierB_taille" = "$journalA_taille" ]
			then
				echo "$fichierA n'est pas conforme au journal, il a été modifié, $fichierB est lui conforme"
				touch -r $fichierA $fichierB
				if [ "$fichierA_droits" != "$fichierB_droits" ]
				then
					echo "Application des droits de $fichierB à $fichierA"
					chmod $fichierB_droits_N $fichierA
				fi
	
			fi

			if [ "$position" = 1 ] && [ "$diff" = 1 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierA_date" != "$journalA_date" ] || [ "$fichierA_heure" != "$journalA_heure" ] || [ "$fichierA_type" != "$journalA_type" ] || [ "$fichierA_droits" != "$journalA_droits" ] || [ "$fichierA_taille" != "$journalA_taille" ] && [ "$fichierB_date" = "$journalA_date" ] && [ "$fichierB_heure" = "$journalA_heure" ] && [ "$fichieB_type" = "$journalA_type" ] && [ "$fichierB_droits" = "$journalA_droits" ] && [ "$fichierB_taille" = "$journalA_taille" ]
			then
				echo "$fichierA n'est pas conforme au journal, il a été modifié, $fichierB est lui conforme"
				if [ "$fichierA_droits" != "$fichierB_droits" ]
				then
					echo "Application des droits de $fichierB à $fichierA"
					chmod $fichierB_droits_N $fichierA
				fi
				echo "$fichierA et $fichierB n'ont pas le même contenu, $fichierA va être remplacé par le contenu de $fichierB"
				cp $fichierB $fichierA
				touch -r $fichierA $fichierB
	
			fi


			if [ "$position" = 1 ] && [ "$diff" = 0 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierB_date" != "$journalB_date" ] || [ "$fichierB_heure" != "$journalB_heure" ] || [ "$fichierB_type" != "$journalB_type" ] || [ "$fichierB_droits" != "$journalB_droits" ] || [ "$fichierB_taille" != "$journalB_taille" ] && [ "$fichierA_date" = "$journalA_date" ] && [ "$fichierA_heure" = "$journalA_heure" ] && [ "$fichierA_type" = "$journalA_type" ] && [ "$fichierA_droits" = "$journalA_droits" ] && [ "$fichierA_taille" = "$journalA_taille" ]
			then
				echo "$fichierB n'est pas conforme au journal, il a été modifié, $fichierA est lui conforme"
				if [ "$fichierB_droits" != "$fichierA_droits" ]
				then
					echo "Application des droits de $fichierA à $fichierB"
					chmod $fichierA_droits_N $fichierB
				fi	
				touch -r $fichierB $fichierA
	
			fi


			if [ "$position" = 1 ] && [ "$diff" = 1 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierB_date" != "$journalB_date" ] || [ "$fichierB_heure" != "$journalB_heure" ] || [ "$fichierB_type" != "$journalB_type" ] || [ "$fichierB_droits" != "$journalB_droits" ] || [ "$fichierB_taille" != "$journalB_taille" ] && [ "$fichierA_date" = "$journalA_date" ] && [ "$fichierA_heure" = "$journalA_heure" ] && [ "$fichierA_type" = "$journalA_type" ] && [ "$fichierA_droits" = "$journalA_droits" ] && [ "$fichierA_taille" = "$journalA_taille" ]
		#mettre les autres métadonnées après $fichierA_nom pour vérifier si A = B en métadonnées autre que le nom ( a voir )
			then
				echo "$fichierB n'est pas conforme au journal, il a été modifié, $fichierA est lui conforme"
				if [ "$fichierB_droits" != "$fichierA_droits" ]
				then
					echo "Application des droits de $fichierA à $fichierB"
					chmod $fichierA_droits_N $fichierB
				fi
				echo "$fichierA et $fichierB n'ont pas le même contenu, $fichierB va être remplacé par le contenu de $fichierA"
				cp $fichierA $fichierB
				touch -r $fichierB $fichierA
	
			fi

		fi

		#Si les deux fichiers ne sont pas conformes aux informations du journal, alors il y a un conflit.
		if [ "$position" = 1 ] && [ -f "$fichierA" ] && [ -f "$fichierB" ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierB_date" != "$journalB_date" ] || [ "$fichierB_heure" != "$journalA_heure" ] || [ "$fichierB_type" != "$journalA_type" ] || [ "$fichierB_droits" != "$journalA_droits" ] || [ "$fichierB_taille" != "$journalA_taille" ] && [ "$fichierA_date" != "$journalA_date" ] || [ "$fichierA_heure" != "$journalA_heure" ] || [ "$fichierA_type" != "$journalA_type" ] || [ "$fichierA_droits" != "$journalA_droits" ] || [ "$fichierA_taille" != "$journalA_taille" ]
		then
			echo "conflit repéré $fichierA et $fichierB ne sont pas conforme au journal"
			let conflit++
		fi
		#Si un fichier est ajouté dans A
                #Si pas le même chemin
                    #On prend le chemin le plus récent et on déplace le $fichierA ou $fichierB à l'emplacement du $fichier le plus récent
		
                    #Synchronisation réussie, on crée une entrée -> JSync
                #Si pas le même contenu
                    #Conflit, on crée une entrée dans listctf.txt des fichiers
                    #On supprime l'entrée du fichier dans le journal
        #Sinon
            #Synchronisation réussie, on crée une entrée -> JSync
    #Sinon
        #let nouveau++
    #Si $nouveau -eq $nbFichierB
        #Synchronisation réussie, on crée une entrée -> JSync
        #On cp le $fichierA dans l'ArbreB
		else
			echo "Entrée dans le journal du fichier $fichierA"
			Jsync
		fi

	fi
	

done
done
#On appelle listcft pour gérer les conflits
lstcft
#copie du contenu du journal temporaire dans le journal principal, puis suppression du secondaire
echo "">"$journal"
cp "$journalTemp" "$journal"
rm "$journalTemp"
}

function Erep {
if [ -e "$ArbreA" ] && [ -d "$ArbreA" ] && [ -e "$ArbreB" ] && [ -d "$ArbreB" ]
then
	echo "Les Arbres A et B existent"
	prmain
else
	echo "Création des arbres A et B"
	mkdir $HOME/synchroniseur
	mkdir $HOME/synchroniseur/A
	mkdir $HOME/synchroniseur/B
	prmain
fi
}


#Création du journal de synchronisation
if [ -f "$journal" ] && [ -e "$journal" ]
then
	echo "journal déjà existant"
	Erep
else
	echo "Le journal n'existe pas, il va maintenant être crée"
	touch $journal
	Erep
	
fi






#Lien sources:
#https://stackoverflow.com/questions/5874090/how-to-get-diff-between-all-files-inside-2-folders-that-are-on-the-web
#https://stackoverflow.com/questions/180741/how-to-do-something-to-each-file-in-a-directory-with-a-batch-script
#https://askubuntu.com/questions/315335/bash-command-for-each-file-in-a-folder



#https://www.ionos.fr/digitalguide/serveur/configuration/commandes-linux/
#https://www.computerhope.com/unix/udiff.htm
#https://www.it-connect.fr/comparez-des-fichiers-entre-eux-avec-diff-sous-linux/
#https://www.funix.org/fr/unix/awk.htm
#http://www.shellunix.com/awk.html

#REP1=$1
#REP2=$2
 
#Le but du test est de récupérer le nombre de lignes
#émises vers la sortie standard via grep -c .
#Si diff émet une ou plusieurs lignes, les dossiers
#sont différents. Sinon ils sont identiques.
#if [ $(diff -r $REP1 $REP2 | grep -c .) -gt 0 ]; then
#    echo "Les répertoires sont différents"
#else
#    echo "Les répertoires sont identiques"
#fi










#for $fichierA in $ArbreA
	#for $fichierB in $ArbreB

		#Si $fichierA et $fichierB sont différents
			#On les ajoute au journal s'ils existent pas
			#break
		#Sinon on fait toute la procédure de vérification de contenu, 			 métadonnées...		

	#done
#done
