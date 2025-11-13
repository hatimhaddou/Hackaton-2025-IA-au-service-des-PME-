-- =====================================================
-- SCHÉMA MYSQL - SUPPORT CLIENT IA
-- Compatible MySQL 5.7+
-- =====================================================
-- Importer ce fichier dans MySQL:
-- mysql -u username -p database_name < schema.sql
-- =====================================================

-- =====================================================
-- TABLE: CLIENTS
-- =====================================================
CREATE TABLE IF NOT EXISTS clients (
    client_id VARCHAR(20) PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telephone VARCHAR(20),
    entreprise VARCHAR(255),
    type_licence VARCHAR(100),
    niveau_technique ENUM('debutant', 'moyen', 'avance') DEFAULT 'moyen',
    nombre_tickets_total INT DEFAULT 0,
    nombre_tickets_resolus_auto INT DEFAULT 0,
    taux_satisfaction FLOAT,
    derniere_interaction DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLE: TICKETS
-- =====================================================
CREATE TABLE IF NOT EXISTS tickets (
    ticket_id VARCHAR(20) PRIMARY KEY,
    client_id VARCHAR(20),
    channel ENUM('email', 'sms', 'phone') NOT NULL,
    subject TEXT NOT NULL,
    content LONGTEXT NOT NULL,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    status ENUM('new', 'auto_resolved', 'escalated', 'in_progress', 'resolved', 'closed') DEFAULT 'new',
    auto_resolvable BOOLEAN DEFAULT FALSE,
    confidence_score FLOAT,
    resolution_type VARCHAR(100),
    resolution_applied TEXT,
    estimated_resolution_time VARCHAR(50),
    actual_resolution_time INT,
    assigned_to VARCHAR(100),
    escalated BOOLEAN DEFAULT FALSE,
    escalation_reason TEXT,
    client_rating INT,
    client_feedback TEXT,
    knowledge_base_ref VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE SET NULL,
    INDEX idx_client_id (client_id),
    INDEX idx_status (status),
    INDEX idx_category (category),
    INDEX idx_created_at (created_at),
    INDEX idx_priority (priority),
    INDEX idx_confidence_score (confidence_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLE: RESOLUTIONS (Base de connaissance)
-- =====================================================
CREATE TABLE IF NOT EXISTS resolutions (
    resolution_id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    problem_description TEXT NOT NULL,
    solution_title VARCHAR(255) NOT NULL,
    solution_steps JSON,
    solution_full_text LONGTEXT,
    success_rate FLOAT,
    times_used INT DEFAULT 0,
    average_resolution_time INT,
    knowledge_base_ref VARCHAR(50) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_kb_ref (knowledge_base_ref),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLE: TICKET_HISTORY (Audit trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS ticket_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id VARCHAR(20),
    action VARCHAR(100) NOT NULL,
    action_by VARCHAR(100),
    action_details JSON,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    INDEX idx_ticket_id (ticket_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLE: AUTOMATION_METRICS (Monitoring IA)
-- =====================================================
CREATE TABLE IF NOT EXISTS automation_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    total_tickets INT DEFAULT 0,
    auto_resolvable_tickets INT DEFAULT 0,
    auto_resolved_tickets INT DEFAULT 0,
    avg_confidence_score FLOAT,
    avg_resolution_time INT,
    automation_rate FLOAT,
    escalation_rate FLOAT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_date (date),
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- VUE: Tickets non résolus
-- =====================================================
CREATE OR REPLACE VIEW v_unresolved_tickets AS
SELECT 
    t.ticket_id,
    t.subject,
    t.priority,
    t.category,
    t.confidence_score,
    t.status,
    t.created_at,
    c.client_id,
    c.nom,
    c.prenom
FROM tickets t
LEFT JOIN clients c ON t.client_id = c.client_id
WHERE t.status IN ('new', 'in_progress', 'escalated')
ORDER BY t.priority DESC, t.created_at ASC;

-- =====================================================
-- VUE: Performance d'automatisation
-- =====================================================
CREATE OR REPLACE VIEW v_automation_performance AS
SELECT 
    DATE(t.created_at) as date,
    COUNT(*) as total_tickets,
    SUM(CASE WHEN t.auto_resolvable THEN 1 ELSE 0 END) as auto_resolvable_count,
    SUM(CASE WHEN t.status = 'auto_resolved' THEN 1 ELSE 0 END) as auto_resolved_count,
    ROUND(AVG(t.confidence_score), 2) as avg_confidence,
    ROUND(SUM(CASE WHEN t.status = 'auto_resolved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as automation_rate
FROM tickets t
GROUP BY DATE(t.created_at)
ORDER BY date DESC;

-- =====================================================
-- FIN - Schéma MySQL
-- =====================================================

-- =====================================================
-- INSERTION DES DONNÉES
-- =====================================================

-- CLIENTS
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL001', 'Dubois', 'Marie', 'marie.dubois@email.com', '+33612345601', 'Tech Solutions SA', 'Microsoft 365 Business', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL002', 'Martin', 'Jean', 'jean.martin@company.fr', '+33612345602', 'Martin SARL', 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL003', 'Bernard', 'Sophie', 'sophie.bernard@corp.com', '+33612345603', 'Corp Industries', 'Microsoft 365 Entreprise', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL004', 'Petit', 'Luc', 'luc.petit@mail.fr', '+33612345604', NULL, 'Microsoft 365 Famille', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL005', 'Robert', 'Julie', 'julie.robert@startup.io', '+33612345605', 'Startup Innov', 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL006', 'Richard', 'Pierre', 'pierre.richard@finance.fr', '+33612345606', 'Finance Corp', 'Microsoft 365 Entreprise', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL007', 'Durand', 'Isabelle', 'i.durand@perso.fr', '+33612345607', NULL, 'Personnel', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL008', 'Moreau', 'Thomas', 'thomas.moreau@agency.com', '+33612345608', 'Creative Agency', 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL009', 'Simon', 'Claire', 'claire.simon@mobile.fr', '+33612345609', NULL, 'Microsoft 365 Famille', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL010', 'Laurent', 'Marc', 'marc.laurent@cloud.tech', '+33612345610', 'Cloud Tech', 'Microsoft 365 Business', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL011', 'Lefebvre', 'Anne', 'anne.lefebvre@example11.com', '+33612345611', NULL, 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL012', 'Roux', 'David', 'david.roux@example12.com', '+33612345612', 'Company 12', 'Microsoft 365 Business', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL013', 'Fournier', 'Laura', 'laura.fournier@example13.com', '+33612345613', NULL, 'Microsoft 365 Business', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL014', 'Girard', 'Vincent', 'vincent.girard@example14.com', '+33612345614', 'Company 14', 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL015', 'Bonnet', 'Emma', 'emma.bonnet@example15.com', '+33612345615', NULL, 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL016', 'Lambert', 'Nicolas', 'nicolas.lambert@example16.com', '+33612345616', 'Company 16', 'Microsoft 365 Famille', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL017', 'Fontaine', 'Sarah', 'sarah.fontaine@example17.com', '+33612345617', NULL, 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL018', 'Rousseau', 'Alexandre', 'alexandre.rousseau@example18.com', '+33612345618', 'Company 18', 'Microsoft 365 Famille', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL019', 'Vincent', 'Camille', 'camille.vincent@example19.com', '+33612345619', NULL, 'Microsoft 365 Business', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL020', 'Muller', 'Julien', 'julien.muller@example20.com', '+33612345620', 'Company 20', 'Microsoft 365 Entreprise', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL021', 'Leroy', 'Charlotte', 'charlotte.leroy@example21.com', '+33612345621', NULL, 'Microsoft 365 Entreprise', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL022', 'Garnier', 'Hugo', 'hugo.garnier@example22.com', '+33612345622', 'Company 22', 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL023', 'Chevalier', 'Léa', 'léa.chevalier@example23.com', '+33612345623', NULL, 'Microsoft 365 Business', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL024', 'Francois', 'Maxime', 'maxime.francois@example24.com', '+33612345624', 'Company 24', 'Microsoft 365 Business', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL025', 'Mercier', 'Alice', 'alice.mercier@example25.com', '+33612345625', NULL, 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL026', 'Blanc', 'Lucas', 'lucas.blanc@example26.com', '+33612345626', 'Company 26', 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL027', 'Guerin', 'Manon', 'manon.guerin@example27.com', '+33612345627', NULL, 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL028', 'Boyer', 'Nathan', 'nathan.boyer@example28.com', '+33612345628', 'Company 28', 'Microsoft 365 Entreprise', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL029', 'Faure', 'Chloé', 'chloé.faure@example29.com', '+33612345629', NULL, 'Microsoft 365 Famille', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL030', 'Andre', 'Tom', 'tom.andre@example30.com', '+33612345630', 'Company 30', 'Microsoft 365 Famille', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL031', 'Renard', 'Inès', 'inès.renard@example31.com', '+33612345631', NULL, 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL032', 'Arnaud', 'Louis', 'louis.arnaud@example32.com', '+33612345632', 'Company 32', 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL033', 'Barbier', 'Jade', 'jade.barbier@example33.com', '+33612345633', NULL, 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL034', 'Denis', 'Théo', 'théo.denis@example34.com', '+33612345634', 'Company 34', 'Microsoft 365 Entreprise', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL035', 'Aubry', 'Zoé', 'zoé.aubry@example35.com', '+33612345635', NULL, 'Microsoft 365 Famille', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL036', 'Bertrand', 'Adam', 'adam.bertrand@example36.com', '+33612345636', 'Company 36', 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL037', 'Roy', 'Lola', 'lola.roy@example37.com', '+33612345637', NULL, 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL038', 'Henry', 'Gabriel', 'gabriel.henry@example38.com', '+33612345638', 'Company 38', 'Microsoft 365 Business', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL039', 'Colin', 'Eva', 'eva.colin@example39.com', '+33612345639', NULL, 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL040', 'Vidal', 'Raphael', 'raphael.vidal@example40.com', '+33612345640', 'Company 40', 'Microsoft 365 Famille', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL041', 'Perez', 'Lina', 'lina.perez@example41.com', '+33612345641', NULL, 'Microsoft 365 Business', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL042', 'Lemaire', 'Arthur', 'arthur.lemaire@example42.com', '+33612345642', 'Company 42', 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL043', 'Gauthier', 'Louise', 'louise.gauthier@example43.com', '+33612345643', NULL, 'Microsoft 365 Famille', 'avance');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL044', 'Perrin', 'Paul', 'paul.perrin@example44.com', '+33612345644', 'Company 44', 'Microsoft 365 Famille', 'moyen');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL045', 'Morel', 'Anna', 'anna.morel@example45.com', '+33612345645', NULL, 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL046', 'Dupont', 'Jules', 'jules.dupont@example46.com', '+33612345646', 'Company 46', 'Microsoft 365 Famille', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL047', 'Leclerc', 'Rose', 'rose.leclerc@example47.com', '+33612345647', NULL, 'Microsoft 365 Entreprise', 'debutant');
INSERT INTO clients (client_id, nom, prenom, email, telephone, entreprise, type_licence, niveau_technique) VALUES ('CL048', 'Carpentier', 'Ethan', 'ethan.carpentier@example48.com', '+33612345648', 'Company 48', 'Microsoft 365 Business', 'moyen');

-- RESOLUTIONS
INSERT INTO resolutions (category, subcategory, problem_description, solution_title, solution_steps, solution_full_text, success_rate, times_used, average_resolution_time, knowledge_base_ref) VALUES ('authentification', 'outlook_login', 'Impossible de se connecter à Outlook', 'Réinitialisation mot de passe Outlook', '["Vérifier Caps Lock", "Aller sur account.microsoft.com", "Réinitialiser mot de passe", "Vider cache", "Retenter"]', 'Réinitialiser le mot de passe via account.microsoft.com', 0.95, 245, 5, 'KB-AUTH-001');
INSERT INTO resolutions (category, subcategory, problem_description, solution_title, solution_steps, solution_full_text, success_rate, times_used, average_resolution_time, knowledge_base_ref) VALUES ('licence', 'office365_activation', 'Licence Office 365 expirée après renouvellement', 'Rafraîchissement licence Office 365', '["Se déconnecter", "Attendre 15 min", "Se reconnecter", "Vérifier statut"]', 'Attendre la propagation de la licence (15-20 minutes)', 0.92, 187, 20, 'KB-LIC-003');
INSERT INTO resolutions (category, subcategory, problem_description, solution_title, solution_steps, solution_full_text, success_rate, times_used, average_resolution_time, knowledge_base_ref) VALUES ('technique', 'teams_crash', 'Teams plante au démarrage', 'Réparation Microsoft Teams', '["Fermer Teams", "Supprimer cache", "Redémarrer", "Réinstaller si échec"]', 'Supprimer le cache Teams et redémarrer', 0.89, 312, 10, 'KB-TEAMS-007');
INSERT INTO resolutions (category, subcategory, problem_description, solution_title, solution_steps, solution_full_text, success_rate, times_used, average_resolution_time, knowledge_base_ref) VALUES ('synchronisation', 'onedrive_sync', 'OneDrive ne synchronise plus', 'Redémarrage synchronisation OneDrive', '["Dissocier PC", "Se reconnecter", "Vérifier espace"]', 'Dissocier puis reconnecter le compte OneDrive', 0.87, 423, 8, 'KB-SYNC-002');
INSERT INTO resolutions (category, subcategory, problem_description, solution_title, solution_steps, solution_full_text, success_rate, times_used, average_resolution_time, knowledge_base_ref) VALUES ('facturation', 'invoice_request', 'Facture introuvable', 'Téléchargement facture Microsoft', '["account.microsoft.com", "Facturation", "Historique", "Télécharger PDF"]', 'Télécharger depuis account.microsoft.com > Facturation', 0.98, 156, 5, 'KB-BILL-001');

-- TICKETS
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK001', 'CL001', 'email', 'Impossible de se connecter à Outlook', 'Bonjour, depuis ce matin je n\'arrive plus à accéder à ma boîte mail Outlook. Message d\'erreur : \'Identifiants incorrects\'. Pourtant mon mot de passe n\'a pas changé.', 'authentification', 'outlook_login', 'high', 1, 'reset_password', '5min', 'KB-AUTH-001', 'auto_resolved', 0.97, 'IA', '2025-01-15T09:23:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK002', 'CL002', 'sms', 'Licence Office 365 expirée', 'Urgent! Mon Office 365 affiche \'Licence expirée\' alors que je viens de renouveler.', 'licence', 'office365_activation', 'medium', 1, 'refresh_licence', '20min', 'KB-LIC-003', 'auto_resolved', 0.86, 'IA', '2025-01-15T10:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK003', 'CL003', 'phone', 'Teams ne démarre pas', 'Bonjour, Microsoft Teams plante au démarrage. Écran blanc puis fermeture automatique. Windows 11.', 'technique', 'teams_crash', 'high', 1, 'app_repair', '10min', 'KB-TEAMS-007', 'auto_resolved', 0.97, 'IA', '2025-01-15T11:45:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK004', 'CL004', 'email', 'OneDrive ne synchronise plus', 'Mes fichiers OneDrive ne se synchronisent plus depuis 2 jours. L\'icône indique \'Synchronisation en pause\' mais je n\'ai rien changé.', 'synchronisation', 'onedrive_sync', 'medium', 1, 'restart_sync', '8min', 'KB-SYNC-002', 'auto_resolved', 0.96, 'IA', '2025-01-15T13:20:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK005', 'CL001', 'email', 'Facture de renouvellement introuvable', 'J\'ai renouvelé ma licence Microsoft 365 Famille il y a 3 jours mais je n\'ai pas reçu la facture par email. J\'en ai besoin pour ma comptabilité.', 'facturation', 'invoice_request', 'low', 1, 'send_invoice', '5min', 'KB-BILL-001', 'auto_resolved', 0.9, 'IA', '2025-01-16T08:10:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK006', 'CL005', 'sms', 'Code de vérification non reçu', 'Je n\'arrive pas à recevoir le code de vérification par SMS pour accéder à mon compte. Ça fait 3 tentatives.', 'authentification', '2fa_sms', 'high', 1, 'alternate_verification', '10min', 'KB-2FA-005', 'auto_resolved', 0.98, 'IA', '2025-01-16T09:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK007', 'CL006', 'phone', 'Excel plante à l\'ouverture de gros fichiers', 'Excel se fige quand j\'ouvre mon fichier de 50 Mo avec beaucoup de formules. Windows affiche \'Ne répond pas\'.', 'performance', 'excel_freeze', 'medium', 0, 'human_escalation', '45min', 'KB-EXCEL-012', 'escalated', 0.67, 'Agent Humain', '2025-01-16T11:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK008', 'CL007', 'email', 'Migration de compte personnel vers professionnel', 'Bonjour, je souhaite transformer mon compte Microsoft personnel en compte professionnel pour mon entreprise. Comment faire ?', 'compte', 'account_conversion', 'low', 1, 'documentation', '5min', 'KB-ACCOUNT-008', 'auto_resolved', 0.96, 'IA', '2025-01-16T14:22:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK009', 'CL008', 'sms', 'PowerPoint ne s\'ouvre plus', 'PowerPoint affiche \'Erreur lors de l\'ouverture\' pour toutes mes présentations. Urgent, j\'ai une présentation cet après-midi !', 'technique', 'powerpoint_error', 'high', 1, 'office_repair', '15min', 'KB-PPT-004', 'auto_resolved', 0.96, 'IA', '2025-01-17T08:45:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK010', 'CL009', 'email', 'Outlook sur mobile ne reçoit pas les emails', 'L\'application Outlook sur mon iPhone ne télécharge plus les nouveaux emails. Synchronisation bloquée à hier.', 'synchronisation', 'outlook_mobile', 'medium', 1, 'mobile_reset', '8min', 'KB-MOBILE-003', 'auto_resolved', 0.88, 'IA', '2025-01-17T10:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK011', 'CL010', 'phone', 'Demande d\'augmentation de stockage OneDrive', 'Mon OneDrive est plein (5 Go utilisés sur 5 Go). Comment obtenir plus d\'espace ? Je suis prêt à payer.', 'stockage', 'onedrive_upgrade', 'low', 1, 'upgrade_plan', '5min', 'KB-STORAGE-001', 'auto_resolved', 0.88, 'IA', '2025-01-17T13:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK012', 'CL011', 'email', 'Activation de Windows 11 échouée', 'Windows 11 affiche \'Windows n\'est pas activé\' après changement de carte mère. Ma licence est légitime.', 'activation', 'windows_activation', 'medium', 0, 'human_escalation', '30min', 'KB-WIN-009', 'escalated', 0.67, 'Agent Humain', '2025-01-17T15:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK013', 'CL012', 'sms', 'Word ne sauvegarde plus', 'Mes documents Word ne se sauvegardent plus. Message \'Erreur lors de l\'enregistrement\'. J\'ai perdu 2h de travail !', 'technique', 'word_save_error', 'high', 1, 'permission_fix', '10min', 'KB-WORD-006', 'auto_resolved', 0.86, 'IA', '2025-01-18T09:10:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK014', 'CL013', 'email', 'Partage de fichier OneDrive impossible', 'Quand j\'essaie de partager un dossier OneDrive avec mes collègues, ils reçoivent \'Accès refusé\'.', 'partage', 'onedrive_sharing', 'medium', 1, 'permissions_config', '5min', 'KB-SHARE-002', 'auto_resolved', 0.94, 'IA', '2025-01-18T11:25:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK015', 'CL014', 'phone', 'Teams bloqué sur \'Connexion en cours\'', 'Teams reste bloqué sur l\'écran de connexion. Roue qui tourne indéfiniment. Testé sur 2 ordinateurs.', 'connexion', 'teams_login_stuck', 'high', 1, 'cache_clear', '12min', 'KB-TEAMS-003', 'auto_resolved', 0.94, 'IA', '2025-01-18T14:40:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK016', 'CL015', 'email', 'Annulation d\'abonnement Microsoft 365', 'Je souhaite annuler mon abonnement Microsoft 365 Famille. Comment procéder pour ne pas être facturé le mois prochain ?', 'abonnement', 'cancellation', 'low', 1, 'cancellation_guide', '5min', 'KB-SUB-004', 'auto_resolved', 0.95, 'IA', '2025-01-19T08:55:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK017', 'CL016', 'sms', 'Outlook envoie mes emails en spam', 'Tous mes emails professionnels Outlook arrivent en spam chez mes clients. Problème urgent pour mon activité !', 'email', 'spam_issue', 'high', 0, 'human_escalation', '60min', 'KB-EMAIL-015', 'escalated', 0.72, 'Agent Humain', '2025-01-19T10:20:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK018', 'CL017', 'email', 'Récupération de compte piraté', 'Mon compte Microsoft a été piraté. Je ne peux plus me connecter et mon email de récupération a été changé. Aide urgente !', 'securite', 'account_compromised', 'critical', 0, 'security_escalation', '120min', 'KB-SEC-001', 'escalated', 0.7, 'Agent Humain', '2025-01-19T13:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK019', 'CL018', 'phone', 'Excel formules ne calculent pas', 'Mes formules Excel affichent du texte au lieu de calculer. Par exemple =SOMME(A1:A10) s\'affiche tel quel.', 'technique', 'excel_formula', 'medium', 1, 'format_fix', '5min', 'KB-EXCEL-008', 'auto_resolved', 0.95, 'IA', '2025-01-19T15:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK020', 'CL019', 'email', 'Installation Office sur Mac échoue', 'L\'installation de Microsoft Office sur mon MacBook Air M2 échoue systématiquement. Message : \'Installation impossible\'.', 'installation', 'office_mac_install', 'medium', 1, 'clean_install', '20min', 'KB-MAC-005', 'auto_resolved', 0.9, 'IA', '2025-01-20T09:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK021', 'CL020', 'sms', 'Teams réunion : caméra ne fonctionne pas', 'En réunion Teams, ma caméra n\'apparaît pas. Audio OK mais vidéo noire.', 'peripherique', 'teams_camera', 'high', 1, 'permission_check', '8min', 'KB-TEAMS-010', 'auto_resolved', 0.9, 'IA', '2025-01-20T11:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK022', 'CL002', 'email', 'Transfert de licence vers nouvel ordinateur', 'J\'ai changé d\'ordinateur. Comment transférer ma licence Office sur le nouveau PC ?', 'licence', 'licence_transfer', 'low', 1, 'deactivation_guide', '10min', 'KB-LIC-007', 'auto_resolved', 0.91, 'IA', '2025-01-20T14:40:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK023', 'CL021', 'phone', 'Outlook ne charge pas les images', 'Les images dans mes emails Outlook n\'apparaissent pas. Juste des carrés rouges avec X.', 'affichage', 'outlook_images', 'low', 1, 'settings_change', '5min', 'KB-OUTLOOK-012', 'auto_resolved', 0.91, 'IA', '2025-01-21T08:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK024', 'CL022', 'email', 'Erreur 0x80070005 lors de la mise à jour Windows', 'Impossible d\'installer les mises à jour Windows. Code erreur 0x80070005 - Accès refusé.', 'mise_a_jour', 'windows_update_error', 'medium', 1, 'troubleshooter', '15min', 'KB-UPDATE-003', 'auto_resolved', 0.89, 'IA', '2025-01-21T10:50:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK025', 'CL023', 'sms', 'OneDrive synchronisation très lente', 'OneDrive synchronise à 10 Ko/s alors que ma connexion est à 100 Mb/s. Ça va prendre des jours !', 'performance', 'onedrive_slow', 'low', 1, 'bandwidth_optimization', '5min', 'KB-SYNC-008', 'auto_resolved', 0.87, 'IA', '2025-01-21T13:25:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK026', 'CL024', 'email', 'Teams enregistrement de réunion indisponible', 'L\'option d\'enregistrement est grisée dans mes réunions Teams. Je suis organisateur pourtant.', 'fonctionnalite', 'teams_recording', 'medium', 1, 'admin_settings', '10min', 'KB-TEAMS-015', 'auto_resolved', 0.91, 'IA', '2025-01-21T15:10:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK027', 'CL025', 'phone', 'Word plante à chaque impression', 'Word se fige dès que je lance une impression. Obligation de fermer avec le Gestionnaire des tâches.', 'impression', 'word_print_crash', 'medium', 1, 'printer_reset', '12min', 'KB-PRINT-004', 'auto_resolved', 0.96, 'IA', '2025-01-22T09:05:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK028', 'CL026', 'email', 'Outlook calendrier ne synchronise pas avec téléphone', 'Mon calendrier Outlook sur PC ne se synchronise plus avec mon iPhone. Les événements ajoutés sur mobile n\'apparaissent pas sur PC.', 'synchronisation', 'calendar_sync', 'medium', 1, 'account_refresh', '10min', 'KB-CAL-002', 'auto_resolved', 0.88, 'IA', '2025-01-22T11:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK029', 'CL027', 'sms', 'PowerPoint vidéo ne se lit pas', 'Les vidéos insérées dans ma présentation PowerPoint ne se lisent pas. Écran noir avec message d\'erreur codec.', 'multimedia', 'powerpoint_video', 'high', 1, 'codec_install', '15min', 'KB-PPT-009', 'auto_resolved', 0.97, 'IA', '2025-01-22T14:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK030', 'CL028', 'email', 'Demande de remboursement double facturation', 'J\'ai été facturé deux fois pour mon abonnement Microsoft 365 ce mois-ci. Demande de remboursement du doublon.', 'facturation', 'refund_request', 'high', 0, 'billing_escalation', '48h', 'KB-BILL-007', 'escalated', 0.66, 'Agent Humain', '2025-01-22T16:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK031', 'CL029', 'phone', 'Excel graphiques disparaissent', 'Mes graphiques Excel disparaissent après sauvegarde et réouverture du fichier. Uniquement sur certains fichiers.', 'technique', 'excel_charts', 'medium', 1, 'file_repair', '20min', 'KB-EXCEL-014', 'auto_resolved', 0.85, 'IA', '2025-01-23T08:20:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK032', 'CL030', 'email', 'Teams notifications ne fonctionnent pas', 'Je ne reçois aucune notification Teams sur Windows alors que tout est activé dans les paramètres.', 'notifications', 'teams_notifications', 'medium', 1, 'notification_reset', '8min', 'KB-TEAMS-012', 'auto_resolved', 0.95, 'IA', '2025-01-23T10:45:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK033', 'CL031', 'sms', 'Outlook règles automatiques ne marchent plus', 'Mes règles Outlook pour trier les emails ne s\'appliquent plus automatiquement depuis hier.', 'automatisation', 'outlook_rules', 'low', 1, 'rules_repair', '10min', 'KB-OUTLOOK-008', 'auto_resolved', 0.86, 'IA', '2025-01-23T13:10:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK034', 'CL032', 'email', 'OneDrive fichiers marqués \'en lecture seule\'', 'Tous mes fichiers OneDrive sont soudainement en lecture seule. Impossible de les modifier.', 'permissions', 'onedrive_readonly', 'high', 1, 'permission_reset', '12min', 'KB-PERM-003', 'auto_resolved', 0.89, 'IA', '2025-01-23T15:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK035', 'CL033', 'phone', 'Word correction automatique trop agressive', 'Word corrige automatiquement des mots techniques que je ne veux pas modifier. C\'est pénible !', 'configuration', 'word_autocorrect', 'low', 1, 'settings_adjustment', '5min', 'KB-WORD-011', 'auto_resolved', 0.97, 'IA', '2025-01-24T09:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK036', 'CL034', 'email', 'Teams appels qualité audio médiocre', 'Mes appels Teams ont une qualité audio horrible. Coupures, écho, son robotique.', 'audio', 'teams_audio_quality', 'high', 1, 'audio_optimization', '10min', 'KB-AUDIO-005', 'auto_resolved', 0.94, 'IA', '2025-01-24T11:20:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK037', 'CL035', 'sms', 'Excel fichier trop lourd', 'Mon fichier Excel fait 120 Mo et rame. Comment réduire sa taille ?', 'optimisation', 'excel_file_size', 'medium', 1, 'file_optimization', '15min', 'KB-EXCEL-010', 'auto_resolved', 0.97, 'IA', '2025-01-24T14:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK038', 'CL036', 'email', 'Outlook signature ne s\'affiche pas', 'Ma signature automatique Outlook configurée n\'apparaît pas dans les nouveaux emails.', 'configuration', 'outlook_signature', 'low', 1, 'signature_reset', '5min', 'KB-OUTLOOK-015', 'auto_resolved', 0.96, 'IA', '2025-01-24T16:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK039', 'CL037', 'phone', 'PowerPoint animation ne fonctionne pas en présentation', 'Les animations de ma présentation PowerPoint fonctionnent en mode édition mais pas en mode diaporama.', 'presentation', 'powerpoint_animation', 'high', 1, 'animation_check', '10min', 'KB-PPT-012', 'auto_resolved', 0.9, 'IA', '2025-01-25T08:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK040', 'CL038', 'email', 'Teams invitation réunion non reçue', 'Mes collègues ne reçoivent pas les invitations aux réunions Teams que je crée.', 'calendrier', 'teams_meeting_invite', 'medium', 1, 'calendar_permissions', '8min', 'KB-CAL-007', 'auto_resolved', 0.87, 'IA', '2025-01-25T10:50:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK041', 'CL039', 'sms', 'OneDrive suppression accidentelle', 'J\'ai supprimé par erreur un dossier complet sur OneDrive. Possible de récupérer ?', 'recuperation', 'onedrive_restore', 'high', 1, 'restore_deleted', '5min', 'KB-RESTORE-001', 'auto_resolved', 0.88, 'IA', '2025-01-25T13:15:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK042', 'CL040', 'email', 'Word fusion et publipostage ne fonctionne pas', 'Impossible de faire un publipostage Word depuis Excel. Message d\'erreur OLE.', 'integration', 'word_mailmerge', 'medium', 1, 'office_repair', '12min', 'KB-MERGE-003', 'auto_resolved', 0.99, 'IA', '2025-01-25T15:40:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK043', 'CL041', 'phone', 'Teams partage d\'écran écran noir', 'Quand je partage mon écran sur Teams, les participants voient un écran noir.', 'partage', 'teams_screenshare', 'high', 1, 'driver_update', '15min', 'KB-SHARE-009', 'auto_resolved', 0.92, 'IA', '2025-01-26T09:10:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK044', 'CL042', 'email', 'Excel VBA macro erreur de sécurité', 'Mes macros Excel ne fonctionnent plus. Message \'Les macros ont été désactivées\'.', 'securite', 'excel_macro_security', 'low', 1, 'security_settings', '5min', 'KB-MACRO-001', 'auto_resolved', 0.93, 'IA', '2025-01-26T11:30:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK045', 'CL043', 'sms', 'Outlook emails archivés introuvables', 'Je ne trouve plus mes anciens emails. Ils ont disparu de ma boîte de réception.', 'archivage', 'outlook_archive', 'medium', 1, 'archive_search', '10min', 'KB-ARCHIVE-002', 'auto_resolved', 0.91, 'IA', '2025-01-26T14:00:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK046', 'CL044', 'email', 'Word numérotation pages incorrecte', 'La numérotation des pages de mon document Word est désordonnée. Page 1, 3, 2, 5...', 'mise_en_page', 'word_page_numbering', 'low', 1, 'section_break_fix', '10min', 'KB-PAGE-004', 'auto_resolved', 0.86, 'IA', '2025-01-26T16:20:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK047', 'CL045', 'phone', 'Teams réunion impossible plus de 100 participants', 'Je ne peux pas inviter plus de 100 personnes à ma réunion Teams. Limite atteinte.', 'limitations', 'teams_capacity', 'medium', 1, 'upgrade_info', '5min', 'KB-LIMITS-001', 'auto_resolved', 0.9, 'IA', '2025-01-27T08:45:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK048', 'CL046', 'email', 'OneDrive erreur synchronisation 0x8004de40', 'OneDrive affiche l\'erreur 0x8004de40 et refuse de synchroniser. Que faire ?', 'erreur', 'onedrive_error_code', 'high', 1, 'reset_onedrive', '10min', 'KB-ERROR-008', 'auto_resolved', 0.95, 'IA', '2025-01-27T11:10:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK049', 'CL047', 'sms', 'Excel impossible d\'ouvrir plusieurs fichiers', 'Quand j\'ouvre un 2ème fichier Excel, il s\'ouvre dans la même fenêtre. Je veux 2 fenêtres séparées.', 'interface', 'excel_multiple_windows', 'low', 1, 'settings_change', '5min', 'KB-UI-003', 'auto_resolved', 0.89, 'IA', '2025-01-27T13:35:00Z');
INSERT INTO tickets (ticket_id, client_id, channel, subject, content, category, subcategory, priority, auto_resolvable, resolution_type, estimated_resolution_time, knowledge_base_ref, status, confidence_score, assigned_to, created_at) VALUES ('TK050', 'CL048', 'email', 'Demande d\'aide configuration domaine personnalisé', 'Je veux utiliser mon propre domaine (monentreprise.com) avec Microsoft 365. Comment configurer ?', 'configuration_avancee', 'custom_domain', 'medium', 0, 'guided_setup', '60min', 'KB-DOMAIN-001', 'escalated', 0.67, 'Agent Humain', '2025-01-27T15:50:00Z');

-- =====================================================
-- FIN - Insertions des données
-- =====================================================
