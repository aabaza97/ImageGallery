//
//  ViewController.swift
//  ImageGallery
//
//  Created by Ahmed Abaza on 17/02/2022.
//

import UIKit

class HomeViewController: UIViewController {
    
    //MARK: -Properties
    private(set) var imagePool: [Image] = [
        Image(aspectRatio: 3/4, backgroudColor: .red),
        Image(aspectRatio: 3/5, backgroudColor: .black),
        Image(aspectRatio: 9/16, backgroudColor: .gray),
        Image(aspectRatio: 1/1, backgroudColor: .green),
        Image(aspectRatio: 1/3, backgroudColor: .blue),
        Image(aspectRatio: 3/4, backgroudColor: .yellow),
        Image(aspectRatio: 3/5, backgroudColor: .purple),
        Image(aspectRatio: 9/16, backgroudColor: .systemPink),
        Image(aspectRatio: 1/1, backgroudColor: .cyan),
        Image(aspectRatio: 1/3, backgroudColor: .brown),
    ]
    
    private var fontSize: CGFloat {
        self.view.bounds.width * SizeRatios.fontSizeToBoundsWidth
    }

    private var font: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: .preferredFont(forTextStyle: .body).withSize(self.fontSize))
    }
    
    private var imageFetcher: ImageFetcher!
    
    
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

    
    private func configure() -> Void {
        
        //RefreshControl setup...
        let attributedText = NSAttributedString(string: "Reloading Images", attributes: [
            .font: self.font,
            .foregroundColor: UIColor.darkGray
        ])
        
        let reloadAction = UIAction { _ in
            DispatchQueue.main.async {
                self.imagePool.shuffle()
                self.galleryCollectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
        
        self.refreshControl.attributedTitle = attributedText
        self.refreshControl.addAction(reloadAction, for: .valueChanged)
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
        cell.backgroundColor = cellImage.backgroudColor
        cell.clipsToBounds = true
        cell.layer.cornerRadius = CollectionViewConsts.cornerRadius
        
        guard let imageURL = cellImage.url else { return cell }
        
        URLSession(configuration: .default).dataTask(with: imageURL) { data, _, error in
            guard let data = data, let source = UIImage(data: data), error == nil else { return }
            DispatchQueue.main.async {
                cell.backgroundView = UIImageView(image: source)
            }
        }.resume()
        
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
extension HomeViewController: UICollectionViewDropDelegate, UICollectionViewDragDelegate, UIDragInteractionDelegate {
  
    
    //MARK: -DROP Interaction Handling....
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
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
            case .none:
                let lastIndexPath = IndexPath(item: self.imagePool.count, section: 0)
                let dropPlaceholder = UICollectionViewDropPlaceholder(insertionIndexPath: lastIndexPath, reuseIdentifier: Consts.placholderId)
                let placeholderManager = coordinator.drop(dropItem.dragItem, to: dropPlaceholder)

                
                dropItem.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { provider, error in
                    guard let url = provider as? URL else { return }
                    
                    URLSession(configuration: .default).dataTask(with: url) { data, _, error in
                        guard let data = data, let source = UIImage(data: data), error == nil else {
                            placeholderManager.deletePlaceholder()
                            return
                        }
                       
                        let image = Image(aspectRatio: source.aspectRatio, backgroudColor: .red, url: url)
                        
                        DispatchQueue.main.async {
                            placeholderManager.commitInsertion { _ in
                                self.imagePool.append(image)
                            }
                            collectionView.scrollToItem(at: lastIndexPath, at: .top, animated: true)
                        }
                    }.resume()
                }
                
                break
                
            default: break
            }
        }
    }
    
    
    
    
    //MARK: -Drag Interaction Handling....
   
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        self.getDragItems(for: indexPath)
    }
    

    
    private func getDragItems(for indexPath: IndexPath) -> [UIDragItem] {
        
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
    
    struct Image {
        let aspectRatio: CGFloat
        let backgroudColor: UIColor
        let url: URL?
        let image: UIImage
        
        init (aspectRatio: CGFloat, backgroudColor: UIColor, url: URL? = nil, image: UIImage = UIImage()) {
            self.aspectRatio = aspectRatio
            self.backgroudColor = backgroudColor
            self.url = url
            self.image = image
        }
    }
    
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
