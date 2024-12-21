// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationStreamingPlatform {

    struct Course {
        uint256 id;
        string title;
        string description;
        string videoUrl;
        uint256 price;
        address payable instructor;
        uint256 viewCount;
    }

    address public owner;
    uint256 public nextCourseId;
    mapping(uint256 => Course) public courses;
    mapping(address => uint256[]) public userPurchasedCourses;
    mapping(uint256 => mapping(address => bool)) public courseAccess;

    event CourseAdded(uint256 courseId, string title, address instructor);
    event CoursePurchased(address student, uint256 courseId);
    event CourseViewed(address student, uint256 courseId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyInstructor(uint256 courseId) {
        require(msg.sender == courses[courseId].instructor, "Only instructor can modify the course");
        _;
    }

    modifier hasAccess(uint256 courseId) {
        require(courseAccess[courseId][msg.sender], "You do not have access to this course");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextCourseId = 1;
    }

    function addCourse(string memory title, string memory description, string memory videoUrl, uint256 price) public {
        require(price >= 0, "Price must be non-negative");

        Course memory newCourse = Course({
            id: nextCourseId,
            title: title,
            description: description,
            videoUrl: videoUrl,
            price: price,
            instructor: payable(msg.sender),
            viewCount: 0
        });

        courses[nextCourseId] = newCourse;
        emit CourseAdded(nextCourseId, title, msg.sender);
        nextCourseId++;
    }

    function purchaseCourse(uint256 courseId) public payable {
        Course storage course = courses[courseId];
        require(msg.value >= course.price, "Insufficient funds to purchase course");

        course.instructor.transfer(msg.value);
        userPurchasedCourses[msg.sender].push(courseId);
        courseAccess[courseId][msg.sender] = true;

        emit CoursePurchased(msg.sender, courseId);
    }

    function viewCourse(uint256 courseId) public hasAccess(courseId) {
        courses[courseId].viewCount++;
        emit CourseViewed(msg.sender, courseId);
    }

    function getPurchasedCourses() public view returns (uint256[] memory) {
        return userPurchasedCourses[msg.sender];
    }

    function getCourseDetails(uint256 courseId) public view returns (string memory, string memory, string memory, uint256, uint256) {
        Course memory course = courses[courseId];
        return (course.title, course.description, course.videoUrl, course.price, course.viewCount);
    }

    function updateCourse(uint256 courseId, string memory title, string memory description, string memory videoUrl, uint256 price) public onlyInstructor(courseId) {
        Course storage course = courses[courseId];
        course.title = title;
        course.description = description;
        course.videoUrl = videoUrl;
        course.price = price;
    }

    function getAllCourses() public view returns (Course[] memory) {
        Course[] memory allCourses = new Course[](nextCourseId - 1);
        for (uint256 i = 1; i < nextCourseId; i++) {
            allCourses[i - 1] = courses[i];
        }
        return allCourses;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
