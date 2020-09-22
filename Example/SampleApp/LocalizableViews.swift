//
//  LocalizableViews.swift
//  cryptoverter
//
//  Created by Mikael on 2018-03-03.
//  Copyright © 2018 Mikael. All rights reserved.
//

import UIKit

@IBDesignable
class LocalizableLabel: UILabel {

    @IBInspectable var localizedString: String? {
        set {
            if let value = newValue {
                text = NSLocalizedString(value, comment: "")
            } else {
                text = nil
            }
        }
        get {
            return text
        }
    }

}

@IBDesignable
class LocalizableButton: UIButton {

    @IBInspectable var localizedString: String? {
        set {
            if let value = newValue {
                setTitle(NSLocalizedString(value, comment: ""), for: .normal)
            } else {
                setTitle(nil, for: .normal)
            }
        }
        get {
            return title(for: .normal)
        }
    }
}
