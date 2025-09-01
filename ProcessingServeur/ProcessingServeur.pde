/***********************************************************************************************************************
 * Nom du fichier : tp3Access.pde                                                                                      *
 * Auteur : Nicolas Arsenault                                                                                          *
 * Date de dernière modification : 9 mai 2024                                                                          *
 * Référence de Processing : https://processing.org/reference.                                                         *
 * Logiciel qui agit comme serveur. Il reçoit les mouvements effectués sur un robot cherokey et envoie les informations*
 * suivantes à une base de données Access: L'IP du robot, l'IP de l'hôte qui envoie les mouvements sur le robot et le  *
 * mouvement lui-même.                                                                                                 *
 **********************************************************************************************************************/
 
import processing.net.*;
PImage imageServeur;

// Variable référençant les connexions qu'établit le logiciel serveur avec des logiciels clients.
processing.net.Server serveur;
com.healthmarketscience.jackcess.Database baseDeDonnees;
com.healthmarketscience.jackcess.Table table;

/*******************
* fonction setup() *
*******************/
void setup()
{ 
  int numeroPortServeur = 5000;
  
  size(500, 250);
  textSize(24);
  fill(0);
  
  imageServeur = loadImage("Serveur.jpg");

  //définir le serveur...
  serveur = new processing.net.Server(this, numeroPortServeur);
  
  //essayer d'ouvrir la base de donnée et la table
  try
  {
    baseDeDonnees = DatabaseBuilder.open(new File(dataPath("/enregistrementMouvements1.accdb")));
   
    table = baseDeDonnees.getTable("enregistrementMouvements");
  }
  catch (IOException erreur)
  {
    println("Un erreur est survenu lors de l'ouverture de la base de données.");
  }
}

/*******************
* fonction draw()  *
*******************/
void draw()
{
  Client client;
 
  background(255);
  image(imageServeur, 20, 20);
  
  //si le serveur est actif...
  if(serveur.active())
  {    
    String ipClientProcessing = "";
    String ipRobot = "";
    int mouvement;
    String mouvementTexte = "";
    
    text("Serveur processing.", 20, 200);
    
    //donner à client la valeur de ce qu'il y a dans le buffer du serveur...
    client = serveur.available();
    
    //si il y a qqch dedans...
    if(client != null)
    {
      //briser la chaine de caractère (qui est sous format X.X.X.XfX.X.X.XfM) ressus pour qu'elle soit prête à être envoyé à la base de donnée.
      ipRobot = client.readStringUntil('f');
      ipClientProcessing = client.readStringUntil('f');
      
      //effacer le 'f' à la fin des IPS
      ipClientProcessing = ipClientProcessing.substring(0, ipClientProcessing.length() - 1);
      ipRobot = ipRobot.substring(0, ipRobot.length() - 1);
      
      //lire le mouvement qui retournera l'ASCII de 0, 1, 2, 3 ou 4
      mouvement = client.read();
      
      switch(mouvement)
      {
        case 48: //arreter ou 0
        {
          mouvementTexte = "ARRETER";
          break;
        }
        case 49: //avancer ou 1
        {
          mouvementTexte = "AVANCER";
          break;
        }
        case 50: //reculer ou 2
        {
          mouvementTexte = "RECULER";
          break;
        }
        case 51: //pivoter sur la droite ou 3
        {
          mouvementTexte = "PIVOTER SUR LA GAUCHE";
          break;
        }
        case 52: //pivoter sur la gauche ou 4
        {
          mouvementTexte = "PIVOTER SUR LA DROITE";
          break;
        }
        
      }
       
     //essayer d'ajouter les données dans les colonnes de la table défini au début. Si ça marche pas, le dire.  
     try
     {
       table.addRow(0, ipRobot, ipClientProcessing, mouvementTexte, 0, 0);
     }
     catch (IOException erreur)
     {
       println("Erreur lors de l'insertion dans la table.");
     }  
    }
  }
  else
  {
    text("Erreur du demarrage logiciel.", 30, 160);
  }
}
