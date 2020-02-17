//
//  ViewController.swift
//  SendiOS
//
//  Created by Annino De Petra on 14/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

func htons(value: CUnsignedShort) -> CUnsignedShort {
    return (value << 8) + (value >> 8)
}

class ViewController: UIViewController {

	@IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet var tableView: UITableView!
	@IBOutlet var textView: UITextView!

	private var messages: [String] = [] {
		didSet {
			tableView.reloadData()
		}
	}

	var address = sockaddr_in()
	var receiverAddress = sockaddr_in()

	let fd: Int32 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
	let receiverFd =  socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

		let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTable))
		tableView.addGestureRecognizer(tap)

		tableView.delegate = self
		tableView.dataSource = self

		if fd < 0 || receiverFd < 0 {
			exit(-1)
		}

		address.sin_family = sa_family_t(AF_INET)
		address.sin_addr.s_addr = inet_addr("192.168.0.255")
		address.sin_port = htons(value: 9010)

		receiverAddress.sin_family = sa_family_t(AF_INET)
		receiverAddress.sin_addr.s_addr = INADDR_ANY
		receiverAddress.sin_port = htons(value: 9010)

		let broadcast = 1;

		withUnsafePointer(to: broadcast) { broadcastPrt in
			setsockopt(fd, SOL_SOCKET, SO_BROADCAST, broadcastPrt, UInt32(MemoryLayout<Int>.size))
			return
		}

		withUnsafePointer(to: receiverAddress) { receiverAddressPtr in
			let r = UnsafeRawPointer(receiverAddressPtr).bindMemory(to: sockaddr.self, capacity: 1)
			bind(receiverFd, r, UInt32(MemoryLayout<sockaddr_in>.stride))
		}

		setSockKqueue(fd: receiverFd)

		var c: String = String()

		withUnsafePointer(to: receiverAddress) { receiverAddressPtr in
			let r = UnsafeRawPointer(receiverAddressPtr).bindMemory(to: sockaddr.self, capacity: 1)
			let mutR: UnsafeMutablePointer<sockaddr> = UnsafeMutablePointer.init(mutating: r)
			var l = UInt32(MemoryLayout<sockaddr_in>.stride)
			recvfrom(receiverFd, &c, c.count, 0, mutR, &l)
		}
	}

	@objc private func didTapTable() {
		view.endEditing(true)
	}

	private func setSockKqueue(fd: Int32) {
		let socketKQueue = kqueue()

		if socketKQueue == -1 {
			 print("Error creating kqueue")
			 exit(EXIT_FAILURE)
		 }

		// Create the kevent structure that sets up our kqueue to listen
        // for notifications
        var sockKevent = kevent(
            ident: UInt(fd),
            filter: Int16(EVFILT_READ),
            flags: UInt16(EV_ADD | EV_ENABLE),
            fflags: 0,
            data: 0,
            udata: nil
        )

        // This is where the kqueue is register with our
        // interest for the notifications described by
        // our kevent structure sockKevent
        kevent(socketKQueue, &sockKevent, 1, nil, 0, nil)

        DispatchQueue.global(qos: .default).async {
            var event = kevent()
            while true {
                let status = kevent(socketKQueue, nil, 0, &event, 1, nil)
                if  status == 0 {
                    print("Timeout")
                } else if status > 0 {
                    if (event.flags & UInt16(EV_EOF)) == EV_EOF {
                        print("The socket (\(fd)) has been closed.")
                        break
                    }
                    print("File descriptor: \(fd) - has \(event.data) characters for reading")
                    self.readFrom(socket: fd)
                } else {
                    print("Error reading kevent")
                    close(socketKQueue)
                    exit(EXIT_FAILURE)
                }
            }
            print("Bye from kevent")
        }
	}

    func readFrom(socket fd: Int32) {
      let MTU = 65536
      var buffer = UnsafeMutableRawPointer.allocate(byteCount: MTU,alignment: MemoryLayout<CChar>.size)

      let readResult = read(fd, &buffer, MTU)

      if (readResult == 0) {
        return  // end of file
      } else if (readResult == -1) {
        print("Error reading form client\(fd) - \(errno)")
        return  // error
      } else {
        //This is an ugly way to add the null-terminator at the end of the buffer we just read
        withUnsafeMutablePointer(to: &buffer) {
          $0.withMemoryRebound(to: UInt8.self, capacity: readResult + 1) {
            $0.advanced(by: readResult).assign(repeating: 0, count: 1)
          }
        }
        let strResult = withUnsafePointer(to: &buffer) {
          $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: readResult)) {
            String(cString: $0)
          }
        }
        print("Received form client \(strResult)")
		DispatchQueue.main.async {
			self.textView.text = ""
			self.messages.insert(strResult, at: 0)
		}

      }
    }

	@IBAction func tap(_ sender: Any) {
		textView.text.withCString { cstr -> Void in
			let sent: Int = withUnsafePointer(to: &address) {

				let broadcastMessageLength = Int(strlen(cstr))
				let p = UnsafeRawPointer($0).bindMemory(to: sockaddr.self, capacity: 1)

				// Send the message
				return sendto(fd, cstr, broadcastMessageLength, 0, p, UInt32(MemoryLayout<sockaddr_in>.stride))
			}
		}
		view.endEditing(true)
	}

	@objc private func keyboardWillShow(_ notification: Notification!) {
		guard
			let userInfo = notification.userInfo,
			let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		else {
			return
		}


		let newBottomConstant = endFrame.height

		if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
			let curve: UIView.AnimationOptions = {
				if let rawCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
					return UIView.AnimationOptions(rawValue: rawCurve)
				}
				return .curveEaseInOut
			}()

			UIView.animate(withDuration: duration, delay: 0, options: [curve], animations: {
				self.textViewBottomConstraint.constant = newBottomConstant
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}

	@objc private func keyboardWillHide(_ notification: Notification!) {

		guard
			let userInfo = notification.userInfo,
			let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		else {
			return
		}

		let newBottomConstant = 0

		if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
			let curve: UIView.AnimationOptions = {
				if let rawCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
					return UIView.AnimationOptions(rawValue: rawCurve)
				}
				return .curveEaseInOut
			}()

			UIView.animate(withDuration: duration, delay: 0, options: [curve], animations: {
				self.textViewBottomConstraint.constant = CGFloat(newBottomConstant)
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

		cell.textLabel?.text = messages[indexPath.row]
		return cell
	}


}

extension Notification {
	/// Returns whether the keyboard is docked
	public var isKeyboardDocked: Bool {
		let keyboardFrame = self.keyboardFrame
		let screenBounds = UIScreen.main.bounds

		return (keyboardFrame.origin.y + keyboardFrame.size.height) >= screenBounds.size.height
	}

	/// Returns the frame of the keyboard.
	///
	/// - Note: If the keyboard is hidden due to a hardware keyboard then its
	///         height remains the same but it's just hidden offscreen with a Y offset.
	public var keyboardFrame: CGRect {
		guard let userInfo = userInfo, let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return .zero
		}

		return keyboardFrame
	}

	/// Returns the frame of the keyboard clipped to a rect in the coordinate space of the screen
	public func keyboardFrame(clippedToRect clippingRect: CGRect) -> CGRect {
		let keyboardFrame = self.keyboardFrame
		let clippedKeyboardFrame = clippingRect.intersection(keyboardFrame)

		return clippedKeyboardFrame
	}

	/// Returns the frame of the keyboard clipped to the screens bounds
	public var keyboardFrameClippedToScreenBounds: CGRect {
		return keyboardFrame(clippedToRect: UIScreen.main.bounds)
	}
}

