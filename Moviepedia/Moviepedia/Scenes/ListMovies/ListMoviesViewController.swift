//
//  ListMoviesViewController.swift
//  Moviepedia
//
//  Created by Lucas Ferraço on 29/08/18.
//  Copyright (c) 2018 Lucas Ferraço. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol ListMoviesDisplayLogic: class {
	func displayMoviesList(with viewModel: ListMovies.ListMovies.ViewModel)
}

class ListMoviesViewController: UIViewController, ListMoviesDisplayLogic {
	var interactor: ListMoviesBusinessLogic?
	var router: (NSObjectProtocol & ListMoviesRoutingLogic & ListMoviesDataPassing)?
	
	fileprivate var collectionManager: MovieCollectionViewManager!
	@IBOutlet weak var moviesCollectionView: UICollectionView!
	fileprivate var refreshControl: UIRefreshControl!
	
	//MARK:- Object lifecycle
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	//MARK:- Setup
	
	private func setup() {
		let viewController = self
		let interactor = ListMoviesInteractor()
		let presenter = ListMoviesPresenter()
		let router = ListMoviesRouter()
		viewController.interactor = interactor
		viewController.router = router
		interactor.presenter = presenter
		presenter.viewController = viewController
		router.viewController = viewController
		router.dataStore = interactor
	}
	
	//MARK:- Routing
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let scene = segue.identifier {
			let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
			if let router = router, router.responds(to: selector) {
				router.perform(selector, with: segue)
			}
		}
	}
	
	//MARK:- View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.title = "Upcoming Movies"
		setupMoviesCollection()
		
		getUpcomingMovies()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		changeScrollOrientation(to: UIApplication.shared.statusBarOrientation)
	}
	
	override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
		changeScrollOrientation(to: toInterfaceOrientation)
	}
	
	//MARK:- ListMoviesDisplayLogic
	
	func displayMoviesList(with viewModel: ListMovies.ListMovies.ViewModel) {
		if refreshControl.isRefreshing {
			refreshControl.endRefreshing()
		}
		
		if let moviesInfo = viewModel.moviesInfo {
			collectionManager.display(movies: moviesInfo)
		} else if let message = viewModel.errorMessage {
			presentAlert(with: message)
		}
	}
	
	//MARK:- Auxiliary Methods
	
	@objc fileprivate func getUpcomingMovies() {
		if !refreshControl.isRefreshing {
			refreshControl.beginRefreshing()
		}
		
		interactor?.getUpcomingMovies()
	}
	
	fileprivate func setupMoviesCollection() {
		moviesCollectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
		moviesCollectionView.alwaysBounceVertical = true
		
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(getUpcomingMovies), for: .valueChanged)
		moviesCollectionView.refreshControl = refreshControl
		
		setupMoviewCollectionManager()
	}
	
	fileprivate func setupMoviewCollectionManager() {
		collectionManager = MovieCollectionViewManager(of: moviesCollectionView)
		collectionManager.delegate = self
		
		moviesCollectionView.dataSource = collectionManager
		moviesCollectionView.delegate = collectionManager
	}
	
	fileprivate func changeScrollOrientation(to interfaceOrientation: UIInterfaceOrientation) {
		guard let layout = moviesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
		
		if interfaceOrientation == .landscapeLeft || interfaceOrientation == .landscapeRight {
			layout.scrollDirection = .horizontal
		} else {
			layout.scrollDirection = .vertical
		}
	}
	
	private func presentAlert(with message: String) {
		let alert = UIAlertController(title: "Ops", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}
}

extension ListMoviesViewController: MovieCollectionViewManagerProtocol {
	func getImageForMovie(with movieInfo: ListMovies.DisplayableMovieInfo, _ completion: @escaping (UIImage) -> Void) {
		let request = ListMovies.GetMovieImage.Request(movieId: movieInfo.id)
		interactor?.getMovieImage(with: request, completion)
	}
	
	
	func getMoreMovies(_ completion: @escaping ([ListMovies.DisplayableMovieInfo]) -> Void) {
		interactor?.getMoreMovies(completion)
	}
	
	func didSelectMovie(with id: Int) {
		interactor?.storeSelectedMovie(with: id)
		router?.routeMovieDetails()
	}
}
