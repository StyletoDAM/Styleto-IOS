//
//  ChatMessage.swift
//  Labasniios
//
//  Modèle de données représentant un message de chat
//
//  Ce fichier définit les structures nécessaires pour représenter
//  un message de chat dans l'application Labasni. Il inclut :
//  - ChatMessage : Le message principal
//  - ChatParticipant : Les participants à la conversation
//  - ExtractedInfo : Informations extraites du message (téléphones, emails, etc.)
//  - Helpers : Structures pour le décodage flexible JSON
//
//  Architecture : Modèle de données (Entity)
//  Dépendances : Foundation, Codable
//

import Foundation

// MARK: - Helper Structures

/**
 * Helper pour décoder des clés dynamiques dans JSON
 * 
 * Permet de décoder des clés JSON qui ne sont pas connues à l'avance.
 * Utilisé pour le décodage flexible des structures MongoDB.
 */
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}

/**
 * Enum pour décoder des valeurs JSON dynamiques
 * 
 * Permet de décoder des valeurs JSON de types variés (String, Int, Double, Bool, Dict, Array, null).
 * Utilisé pour gérer les structures MongoDB complexes où les types peuvent varier.
 * 
 * Cette structure est compatible avec le parsing Android pour garantir
 * la cohérence entre les plateformes.
 */
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case dict([String: AnyCodableValue])
    case array([AnyCodableValue])
    case null
    
    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        default: return nil
        }
    }
    
    var dictValue: [String: AnyCodableValue]? {
        if case .dict(let d) = self {
            return d
        }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dict(dict)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodableValue value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .dict(let d): try container.encode(d)
        case .array(let a): try container.encode(a)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - ChatParticipant

/**
 * Structure représentant un participant à une conversation
 * 
 * Cette structure représente un utilisateur participant à une conversation.
 * Le décodage est flexible pour gérer différents formats depuis le serveur :
 * - ID comme String simple
 * - ID comme objet MongoDB avec "_id" ou "$oid"
 * - Objet complet avec toutes les informations utilisateur
 * 
 * @property id Identifiant unique du participant
 * @property fullName Nom complet du participant
 * @property profilePicture URL de la photo de profil (optionnel)
 */
struct ChatParticipant: Codable, Identifiable {
    let id: String
    let fullName: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case fullName
        case profilePicture
    }
    
    // Décodage flexible : accepte "_id" OU "id" (comme Android parseMessage)
    init(from decoder: Decoder) throws {
        // STRATÉGIE SIMPLIFIÉE ET ROBUSTE :
        // Utiliser directement un keyedContainer (le senderId est toujours un objet JSON)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extraire l'ID : essayer "_id" en premier, puis "id"
        var extractedId: String?
        
        // 1. Essayer "_id" comme String (format MongoDB standard)
        if let objectId = try? container.decode(String.self, forKey: .id) {
            extractedId = objectId
        }
        
        // 2. Essayer "id" comme String (format alternatif)
        if extractedId == nil, let simpleId = try? container.decode(String.self, forKey: .altId) {
            extractedId = simpleId
        }
        
        // 3. Si _id est un objet (ObjectId MongoDB), essayer de décoder comme dictionnaire
        if extractedId == nil {
            if let idDict = try? container.decode([String: AnyCodableValue].self, forKey: .id) {
                // Chercher "$oid" dans le dictionnaire
                extractedId = idDict["$oid"]?.stringValue
            }
        }
        
        guard let finalId = extractedId, !finalId.isEmpty else {
            // Log détaillé pour debug
            print("❌ [ChatParticipant] Impossible d'extraire l'ID.")
            print("   CodingPath: \(decoder.codingPath)")
            let allKeys = container.allKeys
            print("   Clés disponibles: \(allKeys.map { $0.stringValue })")
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Ni _id ni id trouvé dans senderId"
                )
            )
        }
        
        self.id = finalId
        self.fullName = try container.decode(String.self, forKey: .fullName)
        self.profilePicture = try? container.decode(String.self, forKey: .profilePicture)
        
        print("✅ [ChatParticipant] ID extrait: '\(finalId)' pour '\(fullName)'")
    }
    
    // Encodage (nécessaire pour Encodable)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(profilePicture, forKey: .profilePicture)
    }
    
    // Constructeur manuel
    init(id: String, fullName: String, profilePicture: String?) {
        self.id = id
        self.fullName = fullName
        self.profilePicture = profilePicture
    }
}

// MARK: - ExtractedInfo

/**
 * Structure représentant les informations extraites d'un message
 * 
 * Cette structure contient les informations sensibles extraites automatiquement
 * d'un message de chat (téléphones, adresses, emails, URLs) pour permettre
 * leur affichage sécurisé ou leur masquage selon les préférences.
 * 
 * @property phoneNumbers Liste des numéros de téléphone détectés
 * @property addresses Liste des adresses détectées
 * @property emails Liste des emails détectés
 * @property urls Liste des URLs détectées
 */
struct ExtractedInfo: Codable {
    let phoneNumbers: [String]?
    let addresses: [String]?
    let emails: [String]?
    let urls: [String]?
}

// MARK: - ChatMessage

/**
 * Structure représentant un message de chat
 * 
 * Cette structure représente un message individuel dans une conversation.
 * Le décodage est très flexible pour gérer les différents formats MongoDB :
 * - senderId peut être un String (ID simple) ou un objet JSON complet
 * - L'ID peut être dans "id", "_id", ou "$oid" selon le format
 * - Les dates peuvent être en ISO8601 ou timestamp
 * 
 * Cette flexibilité garantit la compatibilité avec différentes versions
 * du backend et différents formats de données MongoDB.
 * 
 * @property id Identifiant unique du message
 * @property conversationId Identifiant de la conversation
 * @property senderId Participant ayant envoyé le message
 * @property content Contenu textuel du message
 * @property createdAt Date de création du message
 * @property extractedInfo Informations extraites du message (optionnel)
 */
struct ChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: ChatParticipant
    let content: String
    let createdAt: Date
    let extractedInfo: ExtractedInfo?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId
        case senderId
        case content
        case createdAt
        case extractedInfo
    }
    
    // Constructeur manuel
    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: ChatParticipant,
         content: String,
         createdAt: Date = Date(),
         extractedInfo: ExtractedInfo? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.createdAt = createdAt
        self.extractedInfo = extractedInfo
    }
    
    // Décodage flexible (comme Android parseMessage)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.conversationId = try container.decode(String.self, forKey: .conversationId)
        self.content = try container.decode(String.self, forKey: .content)
        
        // ✨ DÉCODAGE MANUEL DU senderId (EXACTEMENT comme Android parseMessage)
        // Le senderId peut être un String OU un objet JSON
        var extractedSenderId: String = ""
        var fullName: String = ""
        var profilePicture: String? = nil
        
        // Essayer de décoder comme String d'abord (cas simple)
        if let senderIdString = try? container.decode(String.self, forKey: .senderId) {
            extractedSenderId = senderIdString
            // Si c'est un String, on n'a pas fullName/profilePicture
            fullName = "Utilisateur"
        } else {
            // Décoder comme un objet (dictionnaire JSON)
            let senderIdDict = try container.decode([String: AnyCodableValue].self, forKey: .senderId)
            
            // Extraire l'ID (EXACTEMENT comme Android : chercher "id", "_id", ou "$oid")
            // 1. Chercher "id" (transformé depuis _id par le backend via toObject)
            // Android vérifie: if (idValue is String) extractedId = idValue
            if extractedSenderId.isEmpty {
                if let idValue = senderIdDict["id"] {
                    // Si c'est une String directement
                    if let stringId = idValue.stringValue {
                        extractedSenderId = stringId
                    } else if let idDict = idValue.dictValue {
                        // Si id est un objet (comme Android ligne 616-621), chercher _id dedans
                        if let innerId = idDict["_id"]?.stringValue {
                            extractedSenderId = innerId
                        }
                    }
                }
            }
            
            // 2. Chercher "_id" directement (String)
            // Android vérifie: if (idValue is String) extractedId = idValue
            if extractedSenderId.isEmpty {
                if let idValue = senderIdDict["_id"] {
                    if let stringId = idValue.stringValue {
                        extractedSenderId = stringId
                    } else if let idDict = idValue.dictValue {
                        // Si _id est un objet (ObjectId MongoDB), chercher "$oid"
                        // Android ligne 473-476
                        if let oid = idDict["$oid"]?.stringValue {
                            extractedSenderId = oid
                        }
                    }
                }
            }
            
            // Extraire fullName et profilePicture
            fullName = senderIdDict["fullName"]?.stringValue ?? ""
            profilePicture = senderIdDict["profilePicture"]?.stringValue
        }
        
        guard !extractedSenderId.isEmpty else {
            print("❌ [ChatMessage] Impossible d'extraire senderId.id")
            if let senderIdDict = try? container.decode([String: AnyCodableValue].self, forKey: .senderId) {
                print("   Clés disponibles dans senderId: \(senderIdDict.keys.joined(separator: ", "))")
            }
            throw DecodingError.keyNotFound(
                CodingKeys.senderId,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Impossible d'extraire l'ID du senderId"
                )
            )
        }
        
        // Créer le ChatParticipant manuellement
        self.senderId = ChatParticipant(id: extractedSenderId, fullName: fullName, profilePicture: profilePicture)
        
        print("✅ [ChatMessage] senderId décodé: id='\(extractedSenderId)' (length: \(extractedSenderId.count)), name='\(fullName)'")
        print("   [ChatMessage] senderId normalisé: '\(extractedSenderId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())'")
        
        if let dateStr = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: dateStr) ??
                            { formatter.formatOptions = [.withInternetDateTime]; return formatter.date(from: dateStr) }() ??
                            Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            self.createdAt = Date(timeIntervalSince1970: timestamp / 1000)
        } else {
            self.createdAt = Date()
        }
        
        // ✨ NOUVEAU : Parser extractedInfo
        self.extractedInfo = try? container.decodeIfPresent(ExtractedInfo.self, forKey: .extractedInfo)
    }
}


