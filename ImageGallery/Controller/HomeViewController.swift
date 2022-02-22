//
//  ViewController.swift
//  ImageGallery
//
//  Created by Ahmed Abaza on 17/02/2022.
//

import UIKit

class HomeViewController: UIViewController {
    
    //MARK: -Properties
    
    var imageGallery: Gallery!{
        didSet {
            self.galleryCollectionView.reloadData()
            print("reloaded....")
        }
    }
    
    var isPresentingFromDeleted: Bool = false
    
    var isNewGallery: Bool = false
    
    private var imagePool: [Image]! {
        self.imageGallery.images
    }
    
    private var fontSize: CGFloat {
        self.view.bounds.width * SizeRatios.fontSizeToBoundsWidth
    }
    
    private var font: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: .preferredFont(forTextStyle: .body).withSize(self.fontSize))
    }
    
    
    //MARK: -UI Elements
    private let refreshControl = UIRefreshControl()
    
    
    //MARK: -Outlets
    @IBOutlet weak var galleryCollectionView: UICollectionView!{
        didSet {
            let collectionViewLayout = UICollectionViewFlowLayout()
            
            self.galleryCollectionView.collectionViewLayout = collectionViewLayout
            self.galleryCollectionView.dataSource = self
            self.galleryCollectionView.delegate = self
            self.galleryCollectionView.dropDelegate = self
            self.galleryCollectionView.dragDelegate = self
            self.galleryCollectionView.refreshControl = self.refreshControl
            self.galleryCollectionView.addSubview(self.refreshControl)
            
        }
    }
    
    
    
    //MARK: -LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
    }
    
    
    
    //MARK: - Actions
    @IBAction func didPinchCollectionView(_ sender: UIPinchGestureRecognizer) {
        guard let view = sender.view, view.width >= self.view.width else { return }
        
        if sender.state == .began || sender.state == .changed {
            view.transform = CGAffineTransform(scaleX: sender.scale / 2, y: sender.scale / 2)
            view.invalidateIntrinsicContentSize()
        }
    }
    
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        if !self.isNewGallery {
            guard let indexOfGallery = (Library.shared.galleries.firstIndex { gallery in
                gallery == self.imageGallery
            }) else { return }
            
            Library.shared.updateGallery(from: self.imageGallery, at: indexOfGallery)
        } else {
            Library.shared.saveGallery(self.imageGallery)
        }
    }
    
    
    //MARK: -Functions
    private func configure() -> Void {
        
        //RefreshControl setup...
        let attributedText = NSAttributedString(string: "Reloading Images", attributes: [
            .font: self.font,
            .foregroundColor: UIColor.darkGray
        ])
        
        let reloadAction = UIAction { _ in
            DispatchQueue.main.async {
                self.galleryCollectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
        
        self.refreshControl.attributedTitle = attributedText
        self.refreshControl.addAction(reloadAction, for: .valueChanged)
        
        
        //Gallery Setup
        self.imageGallery = Gallery(images: [Image()], title: "Untitled 1")
    }
    
    
    private func fetchImage(from url: URL?, completion: @escaping (_ image: UIImage) -> Void) -> Void {
        guard let url = url else { return }
        
        URLSession(configuration: .default).dataTask(with: url) { data, _, error in
            guard let data = data, let source = UIImage(data: data), error == nil else { return }
            completion(source)
        }.resume()
    }
    
}



//MARK: -CollectionView
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let aspectRatio = self.imagePool[indexPath.item].aspectRatio
        let collectionViewWidth = self.galleryCollectionView.bounds.width
        let insets = collectionView.contentInset
        let spaceBetweenItemsInRow = CollectionViewConsts.minimumInteritemSpacing
        
        let itemWidth: CGFloat = collectionViewWidth - insets.left - insets.right - spaceBetweenItemsInRow
        let itemHeight: CGFloat = itemWidth * aspectRatio
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Consts.imageCellId, for: indexPath)
        let cellImage = self.imagePool[indexPath.item]
        
        cell.backgroundView = UIView()
        cell.backgroundColor = .darkGray
        cell.clipsToBounds = true
        cell.layer.cornerRadius = CollectionViewConsts.cornerRadius
        
        guard let imageURL = cellImage.url else {
            let iv = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
            iv.contentMode = .scaleAspectFit
            cell.backgroundView = iv
            return cell
        }
        
        self.fetchImage(from: imageURL) { image in
            DispatchQueue.main.async {
                let iv = UIImageView(image: image)
                iv.contentMode = .scaleAspectFit
                cell.backgroundView = iv
            }
        }
        
        return cell
    }
}


extension HomeViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.imagePool.count
    }
}



//MARK: -Drag, drop and Interaction Delegates
extension HomeViewController: UICollectionViewDropDelegate, UICollectionViewDragDelegate {
    
    //MARK: -DROP Interaction Handling....
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if collectionView.hasActiveDrag {
            return session.canLoadObjects(ofClass: NSURL.self)
        } else {
            return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 0 {
            let isDragInsideCollectionView: Bool = (session.localDragSession?.localContext as? UICollectionView) == collectionView
            return UICollectionViewDropProposal(operation: isDragInsideCollectionView ? .move : .copy)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        for dropItem in coordinator.items {
            switch dropItem.sourceIndexPath {
            case .some(let sourceIndexPath):
                let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
                collectionView.performBatchUpdates {
                    // perform batch updates is used when we need to make multiple changes to the collection view one by one...
                    let sourceImage = self.imageGallery.images.remove(at: sourceIndexPath.item)
                    self.imageGallery.images.insert(sourceImage, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }
                
                coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
                break
            case .none:
                let lastIndexPath = IndexPath(item: self.imagePool.count, section: 0)
                let dropPlaceholder = UICollectionViewDropPlaceholder(insertionIndexPath: lastIndexPath, reuseIdentifier: Consts.placholderId)
                let placeholderManager = coordinator.drop(dropItem.dragItem, to: dropPlaceholder)
                
                
                dropItem.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { provider, error in
                    guard let url = provider as? URL else { return }
                    
                    URLSession(configuration: .default).dataTask(with: url) { data, _, error in
                        guard let imageData = data, error == nil else {
                            placeholderManager.deletePlaceholder()
                            return
                        }
                        
                        let image = Image(url: url, image: imageData)
                        
                        DispatchQueue.main.async {
                            placeholderManager.commitInsertion { _ in
                                self.imageGallery.images.append(image)
                            }
                            collectionView.scrollToItem(at: lastIndexPath, at: .top, animated: true)
                        }
                    }.resume()
                }
                
                break
            }
        }
    }
    
    
    
    
    //MARK: -Drag Interaction Handling....
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return self.getDragItems(for: indexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        self.getDragItems(for: indexPath)
    }
    
    private func getDragItems(for indexPath: IndexPath) -> [UIDragItem] {
        guard let url = self.imagePool[indexPath.item].url as NSURL?
        else { return [] }
        
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: url))
        dragItem.localObject = url
        
        return [dragItem]
    }
    
    
    
}


//MARK: -Associated Extensions
extension HomeViewController {
    struct Consts{
        static let imageCellId: String = "imageCell"
        static let placholderId: String = "dropPlaceholderCell"
    }
    
    struct CollectionViewConsts {
        static let numberOfItemsInRow: CGFloat = 2.0
        static let horizontalMargin: CGFloat = 10.0
        static let sectionSpacing: UIEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        static let minimumInteritemSpacing: CGFloat = 10.0
        static let minimumLineSpacing: CGFloat = 0.0
        static let cornerRadius: CGFloat = 12.0
    }
    
    //    struct Image {
    //        let aspectRatio: CGFloat
    //        let backgroudColor: UIColor
    //        let url: URL?
    //        let image: UIImage
    //
    //        init (aspectRatio: CGFloat, backgroudColor: UIColor,
    //              url: URL? = URL(string: "https://www.google.com/images/branding/googlelogo/2x/googlelogo_light_color_272x92dp.png"),
    //              image: UIImage = UIImage()) {
    //            self.aspectRatio = aspectRatio
    //            self.backgroudColor = backgroudColor
    //            self.url = url
    //            self.image = image
    //        }
    //    }
    
    private struct SizeRatios {
        static let fontSizeToBoundsWidth: CGFloat = 0.0385
    }
}


extension UIImage {
    var aspectRatio: CGFloat {
        let imageWidth = self.size.width
        let imageHeight = self.size.height
        
        return imageHeight / imageWidth
    }
}
