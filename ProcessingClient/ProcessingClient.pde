/*******************************************************************************************
 * Nom du fichier : bontp3process.pde
 * Auteur : Nicolas Arsenault
 * Date de dernière modification : 2024-05-02
 * Description du programme : Serveur processing qui permet de se connecter sur un appareil
 * via WiFi (dans notre cas un robot avec plaquette Arduino), il permet ensuite de le 
 * controler avec les touches des flèches (avancer , reculer, etc..)
 * et il lit les données transmise de la plaquette Arduino et les affiches (température et
 * taux d'humidité
 ***************************************************************************************/

import processing.net.*;

Client client; //Contiendra l'humidité et température reçue...
 
Boolean connecteOuNon = false, afficherTemp = false; //connecteOuNon indique si Processing est connecté au robot. AfficherTemp indique quand il faut afficher la temperature et humidité.
int portServeur = 5000, touchePrecedente = 10, finDeLIP = 150; //touchePrecedente prend une valeur bidon. Elle sert à ne pas envoyer constamment des données au serveur Arduino.
String iPfinale = "", dht11TempEtHumidite = "", adresseIP = "192.168.1."; //dht11TempEtHumidite contiendera les données lues du DHT11 du serveur Arduino...
PImage clientImage, boutonRouge, boutonVert, fleches, connexion, deconnexion, triangleHaut, triangleBas; //Images...

/*******************
* Fonction setup() *
*******************/
void setup()
{
  //initialisation pour le visuel...
  size(900, 500);
  background(255);
  textSize(24);
  fill(0);
  
  //initialisation des images...
  clientImage = loadImage("Client.jpg");
  boutonRouge = loadImage("boutonRouge.png");
  boutonVert = loadImage("boutonVert.png");
  connexion = loadImage("connexion.jpg");
  deconnexion = loadImage("dexonnexion.jpg");
  fleches = loadImage("fleches.jpg");
  triangleHaut = loadImage("triangle haut.jpg");
  triangleBas = loadImage("triangle bas.jpg");
  
  iPfinale = adresseIP + finDeLIP; //pour pouvoir afficher une adresse IP au début.
}

/*******************
* Fonction draw()  *
*******************/
void draw()
{
  //afficher les images et un fond blanc...
  background(255);
  image(clientImage, 44, 5);
  image(triangleHaut, 725, 151);
  image(triangleBas, 725, 193);
  image(fleches, 700, 331);
    
  //afficher l'adresse IP que l'usager choisira...
  fill(0);
  textSize(30);
  text(iPfinale, 416, 199); 
  
  //autre affichage
  textSize(20);
  text("Déplacement du robot au clavier :", 542, 305);
  textSize(24); 
   
 //Si le on est connecté au serveur Arduino, afficher la possibilité de se déconnecter, lire le DHT11 ainsi qu'indiquer que l'on peut afficher les données de celui-ci...
 if(connecteOuNon == true)
 {
    image(deconnexion, 3, 130); //afficher le bouton déconnection
    image(boutonVert, 204, 46); //afficher la lumière verte, signifiant qu'on est connecté
    
    //si il y a une connection, vérifier s'il y a quelque chose dans le buffer.
    if(client.active())
    {
      if(client.available() > 0)
      {
        //si oui, lire cette donnée et la mettre dans dht11TempEtHumidite.
       dht11TempEtHumidite = client.readStringUntil('f');
       afficherTemp = true; //indiquer qu'il faut afficher la température
      }
    }
    else
    {
      connecteOuNon = false; //si le client n'est plus actif, l'indiquer...
    }
 }
 else
 {
   //si l'on est pas connecté, afficher l'option de se connecter au serveur et indiquer qu'il ne faut pas montrer les données du DHT11...
    image(connexion, 3, 130);
    image(boutonRouge, 204, 46);
    afficherTemp = false;
 }
 
 //Si il faut afficher ces données, le faire...
 if(afficherTemp == true)
 {
    strokeWeight(1); fill(255); //contour
    rect(8, 297, 351, 199, 48);
    fill(0);
    text("Données reçues du robot Cherokey 150", 15, 282);
    text("Température : " + dht11TempEtHumidite.substring(0, 4) + "°C", 23, 467); //afficher seulement les 4 premiers caractères de la String reçu (ce sera la température)
    text("Humidité : " + dht11TempEtHumidite.substring(4, 6) + "%", 25, 363); //afficher les deux derniers, qui indiqueront l'humidité
 }   
}

/***************************
* Fonction mouseClicked()  *
***************************/
void mouseClicked()
{
  //Lorsque on clique la souris, vérifier si elle est dans le perimètre du bouton connexion, si oui, connecter au Serveur ou déconnecter (selon si on est déja connecté)...
  if(mouseX >= 3 && mouseX < 353 && mouseY >= 130 && mouseY < 250)
  {
    if(connecteOuNon == false)
    {      
      client = new Client(this, iPfinale, portServeur);    
      connecteOuNon = true;
    }
    else
    {   
      client.stop();
      connecteOuNon = false;       
    }  
  }
  
  //Si l'on clique dans les perimètres des flèches pour augmenter ou déscendre l'adresse IP, incrémenter celle-ci en fonction
  if(mouseX >= 725 && mouseX < 795 && mouseY >= 151 && mouseY < 186)
  {
    finDeLIP = finDeLIP + 1;
    
    if(finDeLIP == 255)
    {
      finDeLIP = 2; //si on arrive au bout des adresses possibles aller à la recommencer
    }
    
    //calculer l'adresse IP pour la connexion.
    iPfinale = adresseIP + finDeLIP;
  }
  else
  {
    //Si l'on clique dans les perimètres des flèches pour augmenter ou déscendre l'adresse IP, incrémenter celle-ci en fonction
    if(mouseX >= 725 && mouseX < 795 && mouseY >= 193 && mouseY < 228)
    {
       finDeLIP = finDeLIP -1;
       
       if(finDeLIP == 1)
       {
         finDeLIP = 254; //si on arrive au début des adresses possibles recommencer
       } 
       
       //calculer l'adresse IP pour la connexion.
       iPfinale = adresseIP + finDeLIP;
    }
  }
}

/***************************
* Fonction keyPressed()    *
***************************/
void keyPressed()
{   
  //si il y a une connexion avec le serveur, vérifier si la touche appuyé sur le clavier est une des 4 flèches et si elle n'est pas la même que la touche précédente.
  //Si oui, envoyer la donnée au serveur arduino. Elle indiquera la direction du robot.
  //sauvegarder la touche appuyé dans touchePrecedente, pour ne pas répéter l'envoie de donnée au serveur.
  if(client.active())
  {
    if (key == CODED)
    {
      if (keyCode == UP) 
      {
        if(touchePrecedente != 1)
        {
        client.write(1);
        }
        touchePrecedente = 1;
      }
      else if (keyCode == DOWN) 
      {
        if(touchePrecedente != 2)
        {
          client.write(2);
        }
        touchePrecedente = 2;
      }
      else if (keyCode == LEFT)
      {
        if(touchePrecedente != 3)
        {
         client.write(3); 
        }
        touchePrecedente = 3;
      }
      else if (keyCode == RIGHT)
      {
        if(touchePrecedente != 4)
        {
          client.write(4);
        }
        touchePrecedente = 4;
      }
    }
  }
}

/****************************
* Fonction keyReleased()    *
****************************/
void keyReleased()
{  
  //si la touche est relâcher, envoyer "0" au serveur Arduino, qui indique l'arrêt du robot.
  if(client.active())
  {
    client.write(0);
    touchePrecedente = 0;
  }
}
