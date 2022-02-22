//
//  LibraryTableViewController.swift
//  ImageGallery
//
//  Created by Ahmed Abaza on 22/02/2022.
//

import UIKit

class LibraryTableViewController: UITableViewController {
    
    //MARK: -Properties
    
    ///The list of galleries.
    private var library: Library = Library.shared
    
    
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
    }
    
    
    //MARK: -Actions
    @IBAction func didTapNewGallery(_ sender: UIBarButtonItem) {
        let newGallery = Gallery(images: [Image()], title: "New Gallery")
        guard let galleryController = self.getGalleryController() else { return }
        galleryController.imageGallery = newGallery
        galleryController.isNewGallery = true
        galleryController.isPresentingFromDeleted = false
    }
    
    
    
    //MARK: -Functions
    
    private func configure() -> Void {
        
        //Data confiuguration
        let untitledNewGallery = Gallery(images: [Image()], title: "Untitled 1")
        
        self.library.saveGallery(untitledNewGallery)
        self.library.libraryDelegate = self
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.library.recentlyDeleted.count == 0 {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return self.library.galleries.count
        case 1: return self.library.recentlyDeleted.count
        default: return 0
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Consts.galleryCellId, for: indexPath)
        let gallery = indexPath.section == 0 ? self.library.galleries[indexPath.row] : self.library.recentlyDeleted[indexPath.row]
        var contentConfiguration = cell.defaultContentConfiguration()
        
        // content configuration
        contentConfiguration.text = gallery.title
        contentConfiguration.textProperties.color = .white
        
        // cell configuration
        cell.contentConfiguration = contentConfiguration
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let lbl = UILabel()
        let title = section == 1 ? "Recently Deleted" : ""
        
        lbl.text = title
        lbl.font = .systemFont(ofSize: 15.0, weight: .thin)
        lbl.textColor = .white
        
        return lbl
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50.0
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let galleryViewController = self.getGalleryController() else { return }
        galleryViewController.isNewGallery = false
        
        if indexPath.section == 0 {
            let gallery = self.library.galleries[indexPath.row]
            galleryViewController.isPresentingFromDeleted = false
            galleryViewController.imageGallery = gallery
        } else {
            let gallery = self.library.recentlyDeleted[indexPath.row]
            galleryViewController.isPresentingFromDeleted = true
            galleryViewController.imageGallery = gallery
        }
    }
    
    private func getGalleryController() -> HomeViewController? {
        let navController = self.splitViewController?.viewControllers[1] as? UINavigationController
        
        guard let homeViewController = (navController?.viewControllers[0] as? HomeViewController) else { return nil }
        
        return homeViewController
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard indexPath.section == 0 else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            self.library.deleteGallery(at: indexPath.row)
        }
        
        return  UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else { return nil }
        
        let restoreAction = UIContextualAction(style: .normal, title: "Restore") { _, _, _ in
            self.library.restoreGallery(at: indexPath.row)
        }
        
        return  UISwipeActionsConfiguration(actions: [restoreAction])
    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}



//MARK: - Associated Types
extension LibraryTableViewController {
    struct Consts {
        static let galleryCellId: String = "galleryCell"
    }
}


//MARK: -LibraryDelegate

extension LibraryTableViewController: LibraryDelegate {
    func didFinishJob(_ job: Job) {
        if job == .delete || job == .new || job == .restore {
            self.tableView.reloadData()
        }
    }
}
