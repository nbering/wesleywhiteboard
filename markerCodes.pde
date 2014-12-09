import gab.opencv.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.Core;
import org.opencv.core.Mat;

import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.CvType;


import org.opencv.core.Point;
import org.opencv.core.Size;



class MarkerCodes {

  PImage src, dst, markerImg;

  PImage dst1, dst2;


  ArrayList<MatOfPoint> contours;
  ArrayList<MatOfPoint2f> approximations;
  ArrayList<MatOfPoint2f> markers;

  ArrayList<MatOfPoint2f> nonresult;

  boolean[][] markerCells;

  ArrayList<PImage> markersImages = new ArrayList<PImage>();
  ArrayList<PImage> markersImagesThresholded = new ArrayList<PImage>();

  bekkBoard parent;
  OpenCV opencv;
  int width, height;


  int thresholdval1;
  int thresholdval2;
  int blurval;
  float epsMultiplier;


  /**
   * MarkerCodes class constructor.
   */
  public MarkerCodes (bekkBoard parent, OpenCV opencv, int width, int height) {
    this.parent = parent;
    this.opencv = opencv;
    this.width = width;
    this.height = height;
    setThreshold();
  }

  ArrayList<int []> getMarkerCodes () {
    ArrayList<int []> markerCodes = new ArrayList<int []>();
    return markerCodes;
  }


  ArrayList<PImage> markerImagesUnwarped() {
    return markersImages;
  }


  ArrayList<PImage> markerImagesUnwarpedThresholded() {
    return markersImagesThresholded;
  }


  void drawMarkerImagesUnwarped(int width, int height) {
    translate(width, height);
    pushMatrix();
    scale(0.4*0.5);
    int placement = 0;
    for (PImage img: markerImagesUnwarped()) {
      image(img, placement, 0);
      placement += img.width;
    }
    placement = 0;
    for (PImage img: markerImagesUnwarpedThresholded()) {
      image(img, placement, img.height);
      placement += img.width;
    }
    popMatrix();
  }



  /**
   * cut and paste from draw method in main sketch
   */
  void readNextFrame() {

    opencv.loadImage(video);
    src = video;



    Mat gray = OpenCV.imitate(opencv.getGray());
    opencv.getGray().copyTo(gray);


    Mat thresholdMat = OpenCV.imitate(opencv.getGray());



    opencv.blur(blurval);


    Imgproc.adaptiveThreshold(opencv.getGray(), thresholdMat,
        255, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY_INV,
        thresholdval1, thresholdval2);


    PImage dst3 = createImage(videoWidth, videoHeight, RGB);
    opencv.toPImage(thresholdMat, dst3); // image upper right corner

    contours = new ArrayList<MatOfPoint>();
    Imgproc.findContours(thresholdMat, contours, new Mat(), Imgproc.RETR_LIST,
        Imgproc.CHAIN_APPROX_NONE);

    PImage dst4 = createImage(videoWidth, videoHeight, RGB);
    opencv.toPImage(thresholdMat, dst4); // image lower right corner

    approximations = createPolygonApproximations(contours);

    markers = new ArrayList<MatOfPoint2f>();
    markers = selectMarkers(approximations);




    /**
     * put this into a method on it's own.
     * - warps perspective.
     * - applies threshold.
     * - creates cells.
     * - prints out marker code.
     */
    /*
     * this lines need to do an loop to check all markers.
     */

    MatOfPoint2f canonicalMarker = setupCanonicalMarker();

    Mat transform;


    println("number of markers found: " + markers.size());
    markersImages.clear();
    markersImagesThresholded.clear();



    /**
     * check for rotations...
     */
    for (MatOfPoint2f marker : markers) {
      Mat rotations[] = new Mat[4];
      int distances[] = new int[4];
    }




    /**
     * unwarp and check what code it is.
     * method should take markers as argument (arraylist matofpoint2f)
     * return arraylist of markercodes.
     */
    for (MatOfPoint2f marker : markers) {
      /*
       * legge til en arrayList med markers med en viss kode in som vinkler - to
       * vinkler i en arrayList. Finne ut hvem som er på hvilken side og finne
       * rektangelet mellom disse. Fjerne innholdet i arraylisten etterpå.
       */
      transform = Imgproc.getPerspectiveTransform(marker, canonicalMarker);
      Mat unWarpedMarker = new Mat(50, 50, CvType.CV_8UC1);  
      Imgproc.warpPerspective(gray, unWarpedMarker, transform, new Size(350, 350));


      dst2 = createImage(350, 350, RGB);
      opencv.toPImage(unWarpedMarker, dst2);
      markersImages.add(dst2);

      Imgproc.threshold(unWarpedMarker, unWarpedMarker, 125, 255,
          Imgproc.THRESH_BINARY | Imgproc.THRESH_OTSU);

      dst1 = createImage(350, 350, RGB);
      opencv.toPImage(unWarpedMarker, dst1);
      markersImagesThresholded.add(dst1);

      float cellSize = 350/7.0;

      markerCells = new boolean[7][7];

      // check bekkBoard.pde for bitshift stuff.
      //int markerCode = 1111111111111111111111111111111111111111111111111;

      excludeOverlappingMarkers(markers);
      for (int row = 0; row < 7; row++) {
        for (int col = 0; col < 7; col++) {
          int cellX = int(col*cellSize);
          int cellY = int(row*cellSize);

          Mat cell = unWarpedMarker.submat(cellX, cellX +(int)cellSize, cellY, 
              cellY+ (int)cellSize); 
          markerCells[row][col] = (Core.countNonZero(cell) > (cellSize*cellSize)/2);
        }
      }

      for (int col = 0; col < 7; col++) {
        for (int row = 0; row < 7; row++) {
          if (markerCells[row][col]) {
            print(1);
          } 
          else {
            print(0);
          }
        }
        println();
      }
      println();
    }
    // end for loop

    /*
     * draw source video
     */
    pushMatrix();
    scale(windowScale);
    scale(0.7);
    image(src, 0, 0);
    noFill();
    smooth();
    strokeWeight(5);
    stroke(0, 0, 255);
    //drawContours2f(approximations);
    stroke(255, 0, 0);
    //drawContours2f(nonresult);
    stroke(0, 255, 0);
    drawContours2f(markers);  
    popMatrix();

    /*
     * draw binarization video
     */
    pushMatrix();
    scale(windowScale);
    translate(videoWidth*0.7, 0);
    scale(0.35);
    image(dst3, 0, 0);
    stroke(0, 255, 0);
    drawContours2f(markers);  
    popMatrix();

    /*
     * draw contours video
     */
    pushMatrix();
    scale(windowScale);
    translate(videoWidth*0.7, 0);
    scale(0.35);
    translate(0, videoHeight);
    image(dst4, 0, 0);
    stroke(0, 255, 0);
    drawContours2f(markers);  
    popMatrix();





    /*
     *  draw unwarped tag in video
     */
    /*
       pushMatrix();
       scale(0.4*0.5);
       int placement = 0;
       for (PImage img: markersImages) {
       image(img, placement, 0);
       placement += img.width;
       }
       popMatrix();
     */




    /*
     * draw tags in video
     */
    /*
       pushMatrix();
       scale(0.5);
       translate(0, 0);
       strokeWeight(1);
       if (null != dst) {
       image(dst, 0, 0);
       float cellSize = dst.width/7.0;
       }
     */
    /*
       for (int col = 0; col < 7; col++) {
       for (int row = 0; row < 7; row++) {
       if(markerCells[row][col]){
       fill(255);
       } else {
       fill(0);
       }
       stroke(0,255,0);
       rect(col*cellSize, row*cellSize, cellSize, cellSize);
    //line(i*cellSize, 0, i*cellSize, dst.width);
    //line(0, i*cellSize, dst.width, i*cellSize);
    }
    }
     */
    /*
       popMatrix();
     */



  } // end draw






  /**
   *
   */
  ArrayList<MatOfPoint2f> selectMarkers(ArrayList<MatOfPoint2f> candidates) {
    float minAllowedContourSide = 25;
    minAllowedContourSide = minAllowedContourSide * minAllowedContourSide;

    ArrayList<MatOfPoint2f> result = new ArrayList<MatOfPoint2f>();
    nonresult = new ArrayList<MatOfPoint2f>();

    for (MatOfPoint2f candidate : candidates) {
      //println(candidate.size().height);

      if (candidate.size().height != 4) {
        nonresult.add(candidate);
        continue;
      } 

      if (!Imgproc.isContourConvex(new MatOfPoint(candidate.toArray()))) {
        continue;
      }

      // eliminate markers where consecutive
      // points are too close together
      float minDist = src.width * src.width;
      Point[] points = candidate.toArray();
      for (int i = 0; i < points.length; i++) {
        Point side = new Point(points[i].x - points[(i+1)%4].x,
            points[i].y - points[(i+1)%4].y);
        float squaredLength = (float)side.dot(side);
        // println("minDist: " + minDist  + " squaredLength: " +squaredLength);
        minDist = min(minDist, squaredLength);
      }

      //  println(minDist);


      if (minDist < minAllowedContourSide) {
        continue;
      }

      result.add(candidate);
    }


    return result;
  }



  /**
   *
   */
  ArrayList<MatOfPoint2f> createPolygonApproximations(ArrayList<MatOfPoint> cntrs) {
    ArrayList<MatOfPoint2f> result = new ArrayList<MatOfPoint2f>();

    if (!cntrs.isEmpty()) {
      double epsilon = 0;
      println(":" + epsilon);

      int counter = 0;
      for (MatOfPoint contour : cntrs) {
        epsilon = cntrs.get(counter).size().height * 0.15;
        counter++;
        MatOfPoint2f approx = new MatOfPoint2f();
        Imgproc.approxPolyDP(new MatOfPoint2f(contour.toArray()), approx,
            epsilon, true);
        result.add(approx);
      }
    }

    return result;
  }



  /**
   *
   */
  void drawContours(ArrayList<MatOfPoint> cntrs) {
    for (MatOfPoint contour : cntrs) {
      beginShape();
      Point[] points = contour.toArray();
      for (int i = 0; i < points.length; i++) {
        vertex((float)points[i].x, (float)points[i].y);
      }
      endShape();
    }
  }



  /**
   *
   */
  void drawContours2f(ArrayList<MatOfPoint2f> cntrs) {
    for (MatOfPoint2f contour : cntrs) {
      beginShape();
      Point[] points = contour.toArray();

      for (int i = 0; i < points.length; i++) {
        vertex((float)points[i].x, (float)points[i].y);
      }
      endShape(CLOSE);
    }
  }



  private MatOfPoint2f setupCanonicalMarker() {
    MatOfPoint2f canonicalMarker = new MatOfPoint2f();
    Point[] canonicalPoints = new Point[4];
    canonicalPoints[0] = new Point(0, 350);
    canonicalPoints[1] = new Point(0, 0);
    canonicalPoints[2] = new Point(350, 0);
    canonicalPoints[3] = new Point(350, 350);
    canonicalMarker.fromArray(canonicalPoints);
    return canonicalMarker;
  }


  /**
   * Finds overlapping markers in an ArrayList of MatOfPoint2f markers.
   * Edit's the ArrayList by removing one of the overlapping markers.
   * @param cntrs ArrayList of marker contours.
   */
  public void excludeOverlappingMarkers(ArrayList<MatOfPoint2f> cntrs) {
    ArrayList<Integer> markerCentersX = new ArrayList<Integer>();
    ArrayList<Integer> markerCentersY = new ArrayList<Integer>();
    println("contour list length: " + cntrs.size());
    for (MatOfPoint2f contour : cntrs) {
      Point[] points = contour.toArray();
      int sumX = 0;
      int sumY = 0;
      for (int i = 0; i < points.length; i++) {
        sumX += points[i].x;
        sumY += points[i].y;
        println(contour + ": x: " + points[i].x + "  y: " + points[i].y);
      }
      markerCentersX.add(sumX /= points.length);
      markerCentersY.add(sumY /= points.length);

      /*
      if (cntrs.size() == 2) {
        Point[] pointsA = cntrs.get(0).toArray();
        Point[] pointsB = cntrs.get(1).toArray();
        if (pointsA[0].x < pointsB[1].x && pointsA.X2 > pointsB.X1 &&
                pointsA.Y1 < pointsB.Y2 && pointsA.Y2 > pointsB.Y1)
      }
      */
    }
    for (int i = 1; i < markerCentersX.size(); i++) {
      if (
      Math.abs(markerCentersX.get(i) - markerCentersX.get(i-1)) < 3 &&
      Math.abs(markerCentersY.get(i) - markerCentersY.get(i-1)) < 3) {
        println("overlapping");
        cntrs.remove(i); 
      }
    }
    println("contour list length: " + cntrs.size());
  }


  public void setThreshold() {
    // 25, 4
    thresholdval1 = 21;
    thresholdval2 = 7;
    blurval = 5;
    epsMultiplier = 0.01;
  }
}
