//
//  TaskEditViewController.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 7/2/16.
//  Copyright © 2016 Suyeol Jeon. All rights reserved.
//

import UIKit

final class TaskEditViewController: BaseViewController {

  // MARK: Constants

  struct Metric {
    static let padding = 15.f
    static let titleInputCornerRadius = 5.f
    static let titleInputBorderWidth = 1 / UIScreen.main.scale
  }

  struct Font {
    static let titleLabel = UIFont.systemFont(ofSize: 14)
  }

  struct Color {
    static let titleInputBorder = UIColor.lightGray
  }


  // MARK: Properties

  let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
  let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
  let titleInput = UITextField().then {
    $0.autocorrectionType = .no
    $0.borderStyle = .roundedRect
    $0.font = Font.titleLabel
    $0.placeholder = "Do something..."
  }


  // MARK: Initializing

  init(viewModel: TaskEditViewModelType) {
    super.init()
    self.navigationItem.leftBarButtonItem = self.cancelButtonItem
    self.navigationItem.rightBarButtonItem = self.doneButtonItem
    self.configure(viewModel)
  }

  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.view.addSubview(self.titleInput)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.titleInput.becomeFirstResponder()
  }

  override func setupConstraints() {
    self.titleInput.snp.makeConstraints { make in
      make.top.equalTo(self.topLayoutGuide.snp.bottom).offset(Metric.padding)
      make.left.equalTo(Metric.padding)
      make.right.equalTo(-Metric.padding)
    }
  }


  // MARK: Configuring

  private func configure(_ viewModel: TaskEditViewModelType) {
    // Input
    self.rx.deallocated
      .bindTo(viewModel.viewDidDeallocate)
      .addDisposableTo(self.disposeBag)

    self.cancelButtonItem.rx.tap
      .bindTo(viewModel.cancelButtonItemDidTap)
      .addDisposableTo(self.disposeBag)

    self.doneButtonItem.rx.tap
      .bindTo(viewModel.doneButtonItemDidTap)
      .addDisposableTo(self.disposeBag)

    self.titleInput.rx.text.changed
      .bindTo(viewModel.titleInputDidChangeText)
      .addDisposableTo(self.disposeBag)

    // Output
    viewModel.navigationBarTitle
      .drive(self.navigationItem.rx.title)
      .addDisposableTo(self.disposeBag)

    viewModel.doneButtonEnabled
      .drive(self.doneButtonItem.rx.isEnabled)
      .addDisposableTo(self.disposeBag)

    viewModel.titleInputText
      .drive(self.titleInput.rx.text)
      .addDisposableTo(self.disposeBag)

    viewModel.presentCancelAlert
      .subscribe(onNext: { [weak self, weak viewModel] actions in
        guard let `self` = self, let viewModel = viewModel else { return }
        self.view.endEditing(true)
        let alertController = UIAlertController(
          title: "Really?",
          message: "Changes will be lost.",
          preferredStyle: .alert
        )
        actions
          .map { action -> UIAlertAction in
            let handler: (UIAlertAction) -> Void =  { _ in
              viewModel.cancelAlertDidSelectAction.onNext(action)
            }
            switch action {
            case .leave:
              return UIAlertAction(title: "Leave", style: .destructive, handler: handler)
            case .stay:
              return UIAlertAction(title: "Stay", style: .default, handler: handler)
            }
          }
          .forEach(alertController.addAction)
        self.present(alertController, animated: true, completion: nil)
      })
      .addDisposableTo(self.disposeBag)

    viewModel.dismissViewController
      .subscribe(onNext: { [weak self] in
        self?.view.endEditing(true)
        self?.dismiss(animated: true, completion: nil)
      })
      .addDisposableTo(self.disposeBag)
  }

}
