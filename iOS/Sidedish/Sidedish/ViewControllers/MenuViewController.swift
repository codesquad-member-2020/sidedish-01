//
//  ViewController.swift
//  Sidedish
//
//  Created by kimdo2297 on 2020/04/21.
//  Copyright © 2020 Jason. All rights reserved.
//

import UIKit

final class MenuViewController: UIViewController {
    private let menuTableView = MenuTableView()
    private var hasBeenDisplayed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMenuTableView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.makeMenuViewModels()
        }
    }
    
    private func configureMenuTableView() {
        menuTableView.dataSource = self
        menuTableView.delegate = self
        menuTableView.register(FoodProductCell.self,
                               forCellReuseIdentifier: FoodProductCell.reuseIdentifier)
        menuTableView.register(FoodCategoryHeaderView.self,
                               forHeaderFooterViewReuseIdentifier: FoodCategoryHeaderView.reuseIdentifier)
        configureMenuTableViewConstraints()
    }
    
    private func configureMenuTableViewConstraints() {
        view.addSubview(menuTableView)
        
        let safeArea = view.safeAreaLayoutGuide
        menuTableView.leadingAnchor.constraint(equalTo:
            safeArea.leadingAnchor).isActive = true
        menuTableView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        menuTableView.widthAnchor.constraint(equalTo: safeArea.widthAnchor,
                                             multiplier: 1).isActive = true
        menuTableView.heightAnchor.constraint(equalTo: safeArea.heightAnchor,
                                              multiplier: 1).isActive = true
    }
    
    private var categoryHeaderViewModels: [CategoryHeaderViewModel]! {
        didSet {
            updateTableView()
        }
    }
    
    private var productViewModels: [[ProductViewModel]]! {
        didSet {
            updateTableView()
        }
    }
    
    private func updateTableView() {
        DispatchQueue.main.async {
            self.menuTableView.reloadData()
        }
    }
    
    private func makeMenuViewModels() {
        requestCategoryURLs(with: MockCategoryURLsSuccessStub()) { urlStrings in
            guard let urlStrings = urlStrings else { return }
            self.initCategoryHeaderViewModels(count: urlStrings.count)
            self.initProductsViewModels(count: urlStrings.count)
            for index in 0 ..< urlStrings.count {
                self.makeMenuViewModel(from: urlStrings[index],
                                       with: MockCategorySuccessStub()) { categoryHeaderViewModel, productsViewModel in
                                        guard let categoryHeaderViewModel = categoryHeaderViewModel,
                                            let productsViewModel = productsViewModel else { return }
                                        
                                        self.categoryHeaderViewModels[index] = categoryHeaderViewModel
                                        self.productViewModels[index] = productsViewModel
                }
            }
        }
    }
    
    private func initCategoryHeaderViewModels(count: Int) {
        let dummy = CategoryHeader(id: 0, name: "loading", description: "loading")
        let dummyCategoryHeaderViewModel = CategoryHeaderViewModel(header: dummy)
        categoryHeaderViewModels = [CategoryHeaderViewModel].init(repeating: dummyCategoryHeaderViewModel,
                                                                  count: count)
    }
    
    private func initProductsViewModels(count: Int) {
        productViewModels = [[ProductViewModel]].init(repeating: [], count: count)
    }
    
    private func requestCategoryURLs(with manager: NetworkManagable,
                                     completionHandler: @escaping ([String]?) -> ()) {
        try? manager.requestResource(from: "아직 없음",
                                     httpMethod: .get, httpBody: nil) {
                                        data, urlResponse, error in
                                        guard error == nil, let data = data,
                                            let response = try? JSONDecoder().decode(CategoryURLsResponse.self,
                                                                                     from: data),
                                            response.status == .success else { return }
                                        completionHandler(response.api)
        }
    }
    
    private func makeMenuViewModel(from urlString: String,
                                   with manager: NetworkManagable,
                                   completionHandler: @escaping (CategoryHeaderViewModel?, [ProductViewModel]?) -> ()) {
        try? manager.requestResource(from: urlString, httpMethod: .get, httpBody: nil,
                                     completionHandler: {
                                        data, urlResponse, error in
                                        guard error == nil, let data = data,
                                            let response = try? JSONDecoder().decode(CategoryResponse.self,
                                                                                     from: data),
                                            response.status == .success else { return }
                                        let header = CategoryHeader(id: response.category_id,
                                                                    name: response.category_name,
                                                                    description: response.category_description)
                                        let headerViewModel = CategoryHeaderViewModel(header: header)
                                        let productViewModels =  response.banchans.map { ProductViewModel(product: $0) }
                                        completionHandler(headerViewModel, productViewModels)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        presentLoginViewController()
    }
    
    private func presentLoginViewController() {
        if !hasBeenDisplayed {
            guard let loginViewController = storyboard?.instantiateViewController(withIdentifier: LoginViewController.Identifier.storyboardIdentifier) as? LoginViewController else { return }
            loginViewController.modalPresentationStyle = .fullScreen
            present(loginViewController, animated: true)
            hasBeenDisplayed = true
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let productViewModels = productViewModels else { return 0 }
        return productViewModels[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let productCell = tableView.dequeueReusableCell(withIdentifier: FoodProductCell.reuseIdentifier,
                                                              for: indexPath) as? FoodProductCell else { return FoodProductCell() }
        let productViewModel = productViewModels[indexPath.section][indexPath.row]
        productViewModel.performBind { product in
            productCell.configureTitle(text: product.title)
            productCell.configureSubtitle(text: product.description)
            productCell.configureEventBadges(badges: product.badge)
            
            guard let normalPriceText = productViewModel.text(price: product.normal_price) else { return }
            let salePriceText = productViewModel.text(price: product.sale_price)
            productCell.configure(normalPriceText: normalPriceText,
                                  salePriceText: salePriceText,
                                  unitText: productViewModel.unitText)
        }
        return productCell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let categoryHeaderViewModels = categoryHeaderViewModels else { return 0 }
        return categoryHeaderViewModels.count
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let foodCategoryHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: FoodCategoryHeaderView.reuseIdentifier) as? FoodCategoryHeaderView else { return nil }
        categoryHeaderViewModels[section].performBind { header in
            foodCategoryHeaderView.configureCategory(text: header.name)
            foodCategoryHeaderView.configureTitle(text: header.description)
        }
        return foodCategoryHeaderView
    }
}
