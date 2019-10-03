//
//  SemesterViewModel.swift
//  TAT
//
//  Created by jamfly on 2019/9/13.
//  Copyright © 2019 jamfly. All rights reserved.
//

import Foundation
import Domain
import NetworkPlatform
import RxSwift
import RxCocoa

final class SemesterViewModel: NSObject, ViewModelType {

  struct Input {
    let targetStudentId: Observable<String>
  }

  struct Output {
    let semesters: Observable<[Semester]>
  }

  // MARK: - Properties

  private let curriculumsUseCase: Domain.CurriculumsUseCase

  // MARK: - Init

  override init() { curriculumsUseCase = UseCaseProvider().makeCurriculumsUseCase() }

}

// MARK: - ViewModelType

extension SemesterViewModel {

  func transform(input: SemesterViewModel.Input) -> SemesterViewModel.Output {
    let semesters = input.targetStudentId
      .filter { $0 != "" }
      .flatMap(generateSemesters)
      .share()

    semesters
      .subscribe(onNext: { (semesters) in
        if UserDefaults.standard.object(forKey: "semesters") == nil {
          guard let semesters = try? JSONEncoder().encode(semesters) else { return }
          UserDefaults.standard.set(semesters, forKey: "semesters")
        }
      }, onError: { (error) in
        print(error)
      })
      .disposed(by: rx.disposeBag)

    return Output(semesters: semesters)
  }

}

// MARK: - Private Methods

extension SemesterViewModel {

  private func generateSemesters(from targetStudentId: String) -> Observable<[Semester]> {
    guard let cachedTargetStudentId = UserDefaults.standard.string(forKey: "targetStudentId"),
      cachedTargetStudentId == targetStudentId else {
        UserDefaults.standard.set(targetStudentId, forKey: "targetStudentId")
        return curriculumsUseCase.semesters(targetStudentId: targetStudentId)
    }
    guard let cachedData = UserDefaults.standard.object(forKey: "semesters") as? Data,
      let cachedSemesters = try? JSONDecoder().decode([Semester].self, from: cachedData)
      else { fatalError("cannot cast to semesters") }
    return .just(cachedSemesters)
  }

}
