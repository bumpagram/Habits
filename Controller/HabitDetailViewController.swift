//
//  HabitDetailViewController.swift
//  Habits
//  Created by bumpagram on 10/6/24.
//

import UIKit

class HabitDetailViewController: UIViewController {
    
    @IBOutlet var habitnameLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var collectionview: UICollectionView!
    
    var habit: Habit! // “a property for the habit this view controller will handle”
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        habitnameLabel.text = habit.name
        categoryLabel.text = habit.category.name
        infoLabel.text = habit.info
        
    }
    

    init?(coder: NSCoder, habit: Habit) {
        self.habit = habit
        super.init(coder: coder)
    }
    required init?(coder: NSCoder) { // требование компилятора, если пишешь кастомный failable init
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
